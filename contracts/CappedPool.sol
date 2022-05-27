// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Interfaces.
import './interfaces/ISettings.sol';
import './interfaces/IPoolManagerLogic.sol';
import './interfaces/IPoolManager.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/IAssetVerifier.sol';
import './interfaces/IVerifier.sol';
import './interfaces/ICappedPoolNFT.sol';

// Inheritance.
import './interfaces/ICappedPool.sol';

// Libraries.
import './openzeppelin-solidity/contracts/SafeMath.sol';
import './openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';

contract CappedPool is ICappedPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IAddressResolver public ADDRESS_RESOLVER;
    IPoolManagerLogic public POOL_MANAGER_LOGIC;
    IPoolManager public immutable POOL_MANAGER;
    ICappedPoolNFT public CAPPED_POOL_NFT;
   
    // Pool info.
    string public name;
    address public override manager;
    uint public maxSupply;
    uint public seedPrice;
    uint256 public collectedManagerFees;

    uint256 public unrealizedProfitsAtLastSnapshot;
    uint256 public timestampAtLastSnapshot;
    
    constructor(string memory _poolName, uint256 _seedPrice, uint256 _supplyCap, address _manager, address _addressResolver, address _poolManager) {
        name = _poolName;
        manager = _manager;
        seedPrice = _seedPrice;
        maxSupply = _supplyCap;
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
        POOL_MANAGER = IPoolManager(_poolManager);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the address of the pool's CappedPoolNFT contract.
    */
    function getNFTAddress() external view override returns (address) {
        return address(CAPPED_POOL_NFT);
    }

    /**
    * @notice Returns the number of tokens available for each class.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getAvailableTokensPerClass() external view override returns (uint256, uint256, uint256, uint256) {
        return CAPPED_POOL_NFT.getAvailableTokensPerClass();
    }

    /**
    * @notice Given the address of a user, returns the number of tokens the user has for each class.
    * @param _user Address of the user.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getTokenBalancePerClass(address _user) external view override returns (uint256, uint256, uint256, uint256) {
        return CAPPED_POOL_NFT.getTokenBalancePerClass(_user);
    }

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
        return (totalSupply == 0) ? 0 : getPoolValue().mul(CAPPED_POOL_NFT.balance(_user)).div(CAPPED_POOL_NFT.totalSupply());
    }

    /**
    * @notice Returns the price of the pool's token.
    */
    function tokenPrice() public view override returns (uint256) {
        return _tokenPrice(getPoolValue());
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Purchases the given amount of pool tokens.
    * @dev Call depositAsset.approve() before calling this function.
    * @param _numberOfPoolTokens Number of pool tokens to purchase.
    * @param _depositAsset Address of the asset to deposit.
    */
    function deposit(uint256 _numberOfPoolTokens, address _depositAsset) public override {
        require(POOL_MANAGER_LOGIC.isDepositAsset(_depositAsset), "CappedPool: asset is not available to deposit.");
        require(_numberOfPoolTokens > 0 &&
                totalSupply.add(_numberOfPoolTokens) <= maxSupply,
                "CappedPool: Quantity out of bounds.");

        uint256 poolValue = getPoolValue();
        uint256 USDperDepositAssetToken = IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).getUSDPrice(_depositAsset);
        uint256 amountOfUSD = _tokenPrice(poolValue).mul(_numberOfPoolTokens);

        // Mint pool token NFTs and update cost basis.
        uint256 totalDeposits = CAPPED_POOL_NFT.depositByClass(msg.sender, _numberOfPoolTokens, amountOfUSD);

        IERC20(_depositAsset).safeTransferFrom(msg.sender, address(this), amountOfUSD.div(USDperDepositAssetToken));

        // Update the pool's weight in the farming system.
        POOL_MANAGER.updateWeight(poolValue > totalDeposits ? poolValue.sub(totalDeposits) : 0, _tokenPrice(poolValue));

        emit Deposit(msg.sender, _numberOfPoolTokens, amountOfUSD, _depositAsset, amountOfUSD.div(USDperDepositAssetToken));
    }

    /**
    * @notice Withdraws the user's full investment.
    * @param _numberOfPoolTokens Number of pool tokens to withdraw.
    * @param _tokenClass Token class (C1 - C4) to withdraw from.
    */
    function withdraw(uint256 _numberOfPoolTokens, uint256 _tokenClass) public override {
        require(_tokenClass >= 1 && _tokenClass <= 4, "CappedPool: Token class must be between 1 and 4.");
        require(_numberOfPoolTokens > 0,
                "CappedPool: Withdrawal amount must be greater than 0.");
        require(_numberOfPoolTokens <= CAPPED_POOL_NFT.balanceOf(msg.sender, _tokenClass),
                "CappedPool: Not enough tokens.");
        
        uint256 poolValue = getPoolValue();

        {
        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        uint256 userValue = CAPPED_POOL_NFT.balance(msg.sender).mul(poolValue).div(CAPPED_POOL_NFT.totalSupply());
        uint256 valueWithdrawn = poolValue.mul(numberOfPoolTokens).div(CAPPED_POOL_NFT.totalSupply());
        uint256 unrealizedProfits = (userValue > userDeposits[msg.sender]) ? userValue.sub(userDeposits[msg.sender]) : 0;

        unrealizedProfits = unrealizedProfits.mul(numberOfPoolTokens).div(CAPPED_POOL_NFT.balance(msg.sender));
        collectedManagerFees = collectedManagerFees.add(unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).div(valueWithdrawn).div(10000));

        // Burn the user's pool tokens and update cost basis.
        uint256 totalDeposits = CAPPED_POOL_NFT.burnTokens(msg.sender, _tokenClass, _numberOfPoolTokens);

        uint256[] memory amountsWithdrawn = new uint256[](addresses.length);

        // Withdraw the user's portion of pool's assets.
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 portionOfAssetBalance = _withdrawProcessing(addresses[i], numberOfPoolTokens.mul(10**18).div(CAPPED_POOL_NFT.totalSupply()));
            uint256 fee = unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).mul(portionOfAssetBalance).div(valueWithdrawn).div(10000);

            if (portionOfAssetBalance > 0)
            {
                IERC20(addresses[i]).safeTransfer(manager, fee);
                IERC20(addresses[i]).safeTransfer(msg.sender, portionOfAssetBalance.sub(fee));
                amountsWithdrawn[i] = portionOfAssetBalance;
            }
        }

        emit Withdraw(msg.sender, numberOfPoolTokens, valueWithdrawn, addresses, amountsWithdrawn);
        }

        // Update the pool's weight in the farming system.
        POOL_MANAGER.updateWeight(poolValue > totalDeposits ? poolValue.sub(totalDeposits) : 0, _tokenPrice(poolValue));
    }

    /**
    * @notice Withdraws the user's full investment.
    */
    function exit() external override {
        for (uint256 i = 1; i <= 4; i++) {
            if (CAPPED_POOL_NFT.balanceOf(msg.sender, i) > 0) {
                withdraw(CAPPED_POOL_NFT.balanceOf(msg.sender, i), i);
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Initializes the CappedPoolNFT and PoolManagerLogic contracts.
    * @dev Only the Registry contract can call this function.
    * @dev This function is meant to only be called once, when creating the pool.
    * @param _cappedPoolNFT Address of the CappedPoolNFT contract.
    * @param _poolManagerLogicAddress Address of the PoolManagerLogic contract.
    */
    function initializeContracts(address _cappedPoolNFT, address _poolManagerLogicAddress) external override onlyRegistry {
        CAPPED_POOL_NFT = ICappedPoolNFT(_cappedPoolNFT);
        POOL_MANAGER_LOGIC = IPoolManagerLogic(_poolManagerLogicAddress);

        emit InitializedContracts(_cappedPoolNFT, _poolManagerLogicAddress);
    }

    /**
    * @notice Updates the pool's weight in the farming system based on its current unrealized profits and token price.
    * @dev Only the pool's manager can call this function.
    */
    function takeSnapshot() external onlyPoolManager {
        uint256 poolValue = getPoolValue();
        uint256 totalDeposits = CAPPED_POOL_NFT.totalDeposits();
        uint256 unrealizedProfits = (poolValue > totalDeposits) ? poolValue.sub(totalDeposits) : 0;

        require(unrealizedProfits > unrealizedProfitsAtLastSnapshot,
                "CappedPool: Unrealized profits decreased from last snapshot.");
        require(block.timestamp.sub(timestampAtLastSnapshot) >= ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("TimeBetweenFeeSnapshots"),
                "CappedPool: Not enough time between snapshots.");

        unrealizedProfitsAtLastSnapshot = unrealizedProfits;
        timestampAtLastSnapshot = block.timestamp;

        // Update the pool's weight in the farming system.
        POOL_MANAGER.updateWeight(unrealizedProfits, _tokenPrice(poolValue));

        emit TakeSnapshot(unrealizedProfits);
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
            require(verifier != address(0), "CappedPool: Invalid verifier.");

            // '_to' address is an asset; need to check if the asset is valid.
            require(IAssetHandler(assetHandlerAddress).isValidAsset(_to), "CappedPool: Invalid asset.");
        }
        
        // Verify that the external contract and function signature are valid.
        // Also check that all assets involved in the transaction are supported by Tradegen.
        (bool valid, address receivedAsset, uint256 transactionType) = IVerifier(verifier).verify(address(this), _to, _data);
        require(valid, "CappedPool: Invalid transaction.");
        require(POOL_MANAGER_LOGIC.isAvailableAsset(receivedAsset), "CappedPool: Received asset is not available.");
        
        // Executes the transaction.
        {
        (bool success,) = _to.call(_data);
        require(success, "CappedPool: Transaction failed to execute.");
        }

        // Update the pool's weight in the farming system.
        uint256 poolValue = getPoolValue();
        uint256 totalDeposits = CAPPED_POOL_NFT.totalDeposits();
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
        return (_poolValue == 0) ? seedPrice : _poolValue.div(CAPPED_POOL_NFT.totalSupply());
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
                require(success, "CappedPool: Failed to withdraw.");
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
        require(msg.sender == manager, "CappedPool: Only pool's manager can call this function.");
        _;
    }

    modifier onlyRegistry() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("Registry"), "CappedPool: Only Registry contract can call this function.");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("Operator"), "CappedPool: Only Operator can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(address user, uint256 numberOfPoolTokens, uint256 amountOfUSD, address depositAsset, uint256 tokensDeposited);
    event Withdraw(address user, uint256 numberOfPoolTokens, uint256 valueWithdrawn, address[] assets, uint256[] amountsWithdrawn);
    event ExecutedTransaction(address manager, address to, uint256 transactionType);
    event InitializedContracts(address cappedPoolNFTAddress, address poolManagerLogicAddress);
    event TakeSnapshot(uint256 unrealizedProfits);
}