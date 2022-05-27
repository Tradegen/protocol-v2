// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Inheritance.
import './interfaces/IPool.sol';
import "./openzeppelin-solidity/contracts/ERC20/ERC20.sol";

// Interfaces.
import './interfaces/ISettings.sol';
import './interfaces/IPoolManagerLogic.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/IAssetVerifier.sol';
import './interfaces/IVerifier.sol';

// Libraries.
import "./openzeppelin-solidity/contracts/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";

contract Pool is IPool, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IAddressResolver public immutable ADDRESS_RESOLVER;
    IPoolManagerLogic public POOL_MANAGER_LOGIC;
   
    address public override manager;
    uint256 public collectedManagerFees;

    // Keep track of cost basis to calculate unrealized profits.
    // (user address => user's cost basis).
    mapping (address => uint256) public userDeposits;
    uint256 public totalDeposits;

    constructor(string memory _poolName, address _manager, address _addressResolver) ERC20(_poolName, "") {
        _manager = manager;
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the USD value of the asset.
    * @param _asset Address of the asset.
    * @param _assetHandlerAddress Address of AssetHandler contract.
    */
    function getAssetValue(address _asset, address _assetHandlerAddress) public view override returns (uint256) {
        uint256 USDperToken = IAssetHandler(_assetHandlerAddress).getUSDPrice(_asset);
        uint256 numberOfDecimals = IAssetHandler(_assetHandlerAddress).getDecimals(_asset);
        uint256 assetBalance = IAssetHandler(_assetHandlerAddress).getBalance(address(this), _asset);

        return assetBalance.mul(USDperToken).div(10 ** numberOfDecimals);
    }

    /**
    * @notice Returns the currency address and balance of each position the pool has, as well as the cumulative value.
    * @return (address[], uint256[], uint256) Currency address and balance of each position the pool has, and the cumulative value of positions.
    */
    function getPositionsAndTotal() public view override returns (address[] memory, uint256[] memory, uint256) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        uint256[] memory balances = new uint256[](addresses.length);
        uint256 sum;

        // Calculate the USD value of each asset.
        for (uint256 i = 0; i < addresses.length; i++) {
            balances[i] = IAssetHandler(assetHandlerAddress).getBalance(address(this), addresses[i]);

            uint256 numberOfDecimals = IAssetHandler(assetHandlerAddress).getDecimals(addresses[i]);
            uint256 USDperToken = IAssetHandler(assetHandlerAddress).getUSDPrice(addresses[i]);
            uint256 positionBalanceInUSD = balances[i].mul(USDperToken).div(10 ** numberOfDecimals);
            sum = sum.add(positionBalanceInUSD);
        }


        return (addresses, balances, sum);
    }

    /**
    * @notice Returns the amount of stablecoin the pool has to invest.
    */
    function getAvailableFunds() public view override returns (uint256) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        return IERC20(stableCoinAddress).balanceOf(address(this));
    }

    /**
    * @notice Returns the value of the pool in USD.
    */
    function getPoolValue() public view override returns (uint256) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        uint256 sum;

        // Get the USD value of each asset.
        for (uint256 i = 0; i <= addresses.length; i++) {
            sum = sum.add(getAssetValue(addresses[i], assetHandlerAddress));
        }
        
        return sum;
    }

    /**
    * @notice Returns the balance of the user in USD.
    */
    function getUSDBalance(address _user) public view override returns (uint256) {
        return (totalSupply == 0) ? 0 : getPoolValue().mul(balanceOf(_user)).div(totalSupply());
    }

    /**
    * @notice Returns the price of the pool's token.
    */
    function tokenPrice() public view override returns (uint256) {
        return _tokenPrice(getPoolValue());
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Deposits the given depositAsset amount into the pool.
    * @dev Call depositAsset.approve() before calling this function.
    * @param _depositAsset address of the asset to deposit.
    * @param _amount Amount of depositAsset to deposit into the pool.
    */
    function deposit(address _depositAsset, uint256 _amount) external override {
        require(POOL_MANAGER_LOGIC.isDepositAsset(_depositAsset), "Pool: Asset is not available to deposit.");
        require(_amount > 0, "Pool: Deposit must be greater than 0.");

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        uint256 USDperToken = IAssetHandler(assetHandlerAddress).getUSDPrice(_depositAsset);
        uint256 userUSDValue = _amount.mul(USDperToken).div(10 ** IAssetHandler(assetHandlerAddress).getDecimals(_depositAsset));
        uint256 numberOfPoolTokens = (totalSupply() > 0) ? totalSupply().mul(userUSDValue).div(getPoolValue()) : userUSDValue;

        // Mint pool tokens and transfer them to the user.
        _mint(msg.sender, numberOfPoolTokens);

        // Update the cost basis.
        userDeposits[msg.sender] = userDeposits[msg.sender].add(userUSDValue);
        totalDeposits = totalDeposits.add(userUSDValue);

        IERC20(_depositAsset).safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount, userUSDValue, _depositAsset, _amount);
    }

    /**
    * @notice Withdraws the given number of pool tokens from the user.
    * @param _numberOfPoolTokens Number of pool tokens to withdraw.
    */
    function withdraw(uint256 _numberOfPoolTokens) public override {
        require(_numberOfPoolTokens > 0, "Pool: Number of pool tokens must be greater than 0.");
        require(balanceOf(msg.sender) >= _numberOfPoolTokens, "Pool: Not enough pool tokens to withdraw.");

        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        uint256 poolValue = getPoolValue();
        uint256 userValue = balanceOf(msg.sender).mul(poolValue).div(totalSupply());
        uint256 valueWithdrawn = getPoolValue().mul(_numberOfPoolTokens).div(totalSupply());
        uint256 unrealizedProfits = (userValue > userDeposits[msg.sender]) ? userValue.sub(userDeposits[msg.sender]) : 0;

        unrealizedProfits = unrealizedProfits.mul(_numberOfPoolTokens).div(balanceOf(msg.sender));
        collectedManagerFees = collectedManagerFees.add(unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).div(valueWithdrawn).div(10000));

        // Update the cost basis.
        totalDeposits = totalDeposits.sub(userDeposits[msg.sender].mul(_numberOfPoolTokens).div(balanceOf(msg.sender)));
        userDeposits[msg.sender] = userDeposits[msg.sender].sub(userDeposits[msg.sender].mul(_numberOfPoolTokens).div(balanceOf(msg.sender)));

        // Burn the user's pool tokens.
        _burn(msg.sender, numberOfPoolTokens);

        uint256[] memory amountsWithdrawn = new uint256[](addresses.length);

        // Withdraw user's portion of pool's assets.
        for (uint i = 0; i < addresses.length; i++) {
            uint256 portionOfAssetBalance = _withdrawProcessing(addresses[i], _numberOfPoolTokens.mul(10**18).div(totalSupply()));
            uint256 fee = unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).mul(portionOfAssetBalance).div(valueWithdrawn).div(10000);

            if (portionOfAssetBalance > 0) {
                IERC20(addresses[i]).safeTransfer(manager, fee);
                IERC20(addresses[i]).safeTransfer(msg.sender, portionOfAssetBalance.sub(fee));
                amountsWithdrawn[i] = portionOfAssetBalance;
            }
        }

        emit Withdraw(msg.sender, numberOfPoolTokens, valueWithdrawn, addresses, amountsWithdrawn);
    }

    /**
    * @notice Withdraws the user's full investment.
    */
    function exit() external override {
        withdraw(balanceOf(msg.sender));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Initializes the pool's PoolManagerLogic contract.
    * @dev Only the Registry contract can call this function.
    * @dev This function is meant to only be called once, when creating the pool.
    * @param _poolManagerLogicAddress Address of the PoolManagerLogic contract.
    */
    function setPoolManagerLogic(address _poolManagerLogicAddress) external override onlyRegistry {
        POOL_MANAGER_LOGIC = IPoolManagerLogic(_poolManagerLogicAddress);

        emit SetPoolManagerLogic( _poolManagerLogicAddress);
    }

    /**
    * @notice Executes a transaction on behalf of the pool, letting the pool interact with other external contracts.
    * @dev Only the pool's manager can call this function.
    * @param _to Address of external contract.
    * @param _data Bytes data for the transaction.
    */
    function executeTransaction(address _to, bytes memory _data) external onlyPoolManager {
        // First try to get the contract verifier.
        address verifier = ADDRESS_RESOLVER.contractVerifiers(_to);

        // Try to get the asset verifier if no contract verifier was found.
        if (verifier == address(0)) {
            address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
            verifier = IAssetHandler(assetHandlerAddress).getVerifier(_to);

            // Check if the asset verifier is found.
            // If no asset verifier is found, then the asset is not supported on this platform.
            require(verifier != address(0), "Pool: Invalid verifier.");

            // '_to' address is an asset; need to check if the asset is valid.
            require(IAssetHandler(assetHandlerAddress).isValidAsset(_to), "Pool: Invalid asset.");
        }
        
        // Verify that the external contract and function signature are valid.
        // Also check that all assets involved in the transaction are supported by Tradegen.
        (bool valid, address receivedAsset, uint256 transactionType) = IVerifier(verifier).verify(address(this), _to, _data);
        require(valid, "Pool: Invalid transaction.");
        require(POOL_MANAGER_LOGIC.isAvailableAsset(receivedAsset), "Pool: Received asset is not available.");
        
        // Executes the transaction.
        {
        (bool success,) = _to.call(_data);
        require(success, "Pool: Transaction failed to execute.");
        }

        // Update the pool's weight in the farming system.
        uint256 poolValue = getPoolValue();
        POOL_MANAGER.updateWeight(poolValue > totalDeposits ? poolValue.sub(totalDeposits) : 0, _tokenPrice(poolValue));

        emit ExecutedTransaction(manager, _to, transactionType);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @notice Calculates the price of a pool token.
    * @param _poolValue Value of the pool in USD.
    * @return uint256 Price of a pool token.
    */
    function _tokenPrice(uint256 _poolValue) internal view returns (uint256) {
        return (_poolValue == 0) ? seedPrice : _poolValue.div(totalSupply());
    }

    /**
    * @notice Performs additional processing when withdrawing an asset (such as checking for staked tokens).
    * @param _asset Address of asset to withdraw.
    * @param _portion User's portion of pool's asset balance.
    * @return uint256 Amount of tokens to withdraw.
    */
    function _withdrawProcessing(address _asset, uint256 _portion) internal returns (uint256) {
        address verifier = IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).getVerifier(_asset);

        IAssetVerifier.WithdrawalData memory withdrawalData = IAssetVerifier(verifier).prepareWithdrawal(address(this), _asset, _portion);

        if (withdrawalData.externalAddresses.length > 0) {
            uint256 initialAssetBalance = (withdrawalData.withdrawalAsset != address(0)) ? IERC20(withdrawalData.withdrawalAsset).balanceOf(address(this)) : 0;

            // Execute each transaction.
            for (uint256 i = 0; i < withdrawalData.externalAddresses.length; i++) {
                (bool success,) = (withdrawalData.externalAddresses[i]).call(withdrawalData.transactionDatas[i]);
                require(success, "Pool: Failed to withdraw.");
            }

            // Account for additional tokens added (withdrawing staked LP tokens).
            if (withdrawalData.withdrawalAsset != address(0)) {
                withdrawalData.withdrawalAmount = withdrawalData.withdrawalAmount.add(IERC20(withdrawalData.withdrawalAsset).balanceOf(address(this))).sub(initialAssetBalance);
            }
        }

        return withdrawalData.withdrawalAmount;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyPoolManager() {
        require(msg.sender == manager, "Pool: Only pool's manager can call this function.");
        _;
    }

    modifier onlyRegistry() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("Registry"), "Pool: Only the Registry contract can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(address user, uint256 amount, uint256 userUSDValue, address depositAsset, uint256 tokensDeposited);
    event Withdraw(address user, uint256 numberOfPoolTokens, uint256 valueWithdrawn, address[] assets, uint256[] amountsWithdrawn);
    event ExecutedTransaction(address manager, address to, uint256 transactionType);
    event SetPoolManagerLogic(address poolManagerLogicAddress);
}