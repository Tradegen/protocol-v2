// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Inheritance
import './interfaces/IPool.sol';
import "./openzeppelin-solidity/contracts/ERC20/ERC20.sol";

//Interfaces
import './interfaces/ISettings.sol';
import './interfaces/IPoolManagerLogic.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/IAssetVerifier.sol';
import './interfaces/IVerifier.sol';

//Libraries
import "./openzeppelin-solidity/contracts/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";

contract Pool is IPool, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IAddressResolver public immutable ADDRESS_RESOLVER;
    IPoolManagerLogic public immutable POOL_MANAGER_LOGIC;
   
    address public override manager;
    uint256 public collectedManagerFees;

    mapping (address => uint256) public userDeposits;
    uint256 public totalDeposits;

    constructor(string memory _poolName, address _manager, address _addressResolver, address _poolManagerLogic) ERC20(_poolName, "") {
        _manager = manager;
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
        POOL_MANAGER_LOGIC = IPoolManagerLogic(_poolManagerLogic);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the USD value of the asset
    * @param asset Address of the asset
    * @param assetHandlerAddress Address of AssetHandler contract
    */
    function getAssetValue(address asset, address assetHandlerAddress) public view override returns (uint) {
        require(asset != address(0), "Pool: invalid asset address");
        require(assetHandlerAddress != address(0), "Pool: invalid asset handler address");

        uint USDperToken = IAssetHandler(assetHandlerAddress).getUSDPrice(asset);
        uint numberOfDecimals = IAssetHandler(assetHandlerAddress).getDecimals(asset);
        uint balance = IAssetHandler(assetHandlerAddress).getBalance(address(this), asset);

        return balance.mul(USDperToken).div(10 ** numberOfDecimals);
    }

    /**
    * @dev Returns the currency address and balance of each position the pool has, as well as the cumulative value
    * @return (address[], uint[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions
    */
    function getPositionsAndTotal() public view override returns (address[] memory, uint[] memory, uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        uint[] memory balances = new uint[](addresses.length);
        uint sum;

        //Calculate USD value of each asset
        for (uint i = 0; i < addresses.length; i++)
        {
            balances[i] = IAssetHandler(assetHandlerAddress).getBalance(address(this), addresses[i]);

            uint numberOfDecimals = IAssetHandler(assetHandlerAddress).getDecimals(addresses[i]);
            uint USDperToken = IAssetHandler(assetHandlerAddress).getUSDPrice(addresses[i]);
            uint positionBalanceInUSD = balances[i].mul(USDperToken).div(10 ** numberOfDecimals);
            sum = sum.add(positionBalanceInUSD);
        }

        return (addresses, balances, sum);
    }

    /**
    * @dev Returns the amount of mcUSD the pool has to invest
    * @return uint Amount of mcUSD the pool has available
    */
    function getAvailableFunds() public view override returns (uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        return IERC20(stableCoinAddress).balanceOf(address(this));
    }

    /**
    * @dev Returns the value of the pool in USD
    * @return uint Value of the pool in USD
    */
    function getPoolValue() public view override returns (uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        uint sum = 0;

        //Get USD value of each asset
        for (uint i = 0; i <= addresses.length; i++)
        {
            sum = sum.add(getAssetValue(addresses[i], assetHandlerAddress));
        }
        
        return sum;
    }

    /**
    * @dev Returns the balance of the user in USD
    * @return uint Balance of the user in USD
    */
    function getUSDBalance(address user) public view override returns (uint) {
        require(user != address(0), "Invalid address");

        if (totalSupply() == 0)
        {
            return 0;
        }

        uint poolValue = getPoolValue();

        return poolValue.mul(balanceOf(user)).div(totalSupply());
    }

    /**
    * @dev Returns the price of the pool's token
    * @return USD price of the pool's token
    */
    function tokenPrice() public view override returns (uint) {
        uint poolValue = getPoolValue();

        if (totalSupply() == 0 || poolValue == 0)
        {
            return 10**18;
        }

        return poolValue.mul(10**18).div(totalSupply());
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Deposits the given depositAsset amount into the pool
    * @notice Call depositAsset.approve() before calling this function
    * @param _depositAsset address of the asset to deposit
    * @param _amount Amount of depositAsset to deposit into the pool
    */
    function deposit(address _depositAsset, uint _amount) external override {
        require(POOL_MANAGER_LOGIC.isDepositAsset(_depositAsset), "Pool: asset is not available to deposit.");
        require(_amount > 0, "Pool: Deposit must be greater than 0");

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        uint USDperToken = IAssetHandler(assetHandlerAddress).getUSDPrice(_depositAsset);
        uint userUSDValue = _amount.mul(USDperToken).div(10 ** IAssetHandler(assetHandlerAddress).getDecimals(_depositAsset));
        uint numberOfPoolTokens = (totalSupply() > 0) ? totalSupply().mul(userUSDValue).div(getPoolValue()) : userUSDValue;

        _mint(msg.sender, numberOfPoolTokens);
        userDeposits[msg.sender] = userDeposits[msg.sender].add(userUSDValue);
        totalDeposits = totalDeposits.add(userUSDValue);

        IERC20(_depositAsset).safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(address(this), msg.sender, _amount, userUSDValue);
    }

    /**
    * @dev Withdraws the given number of pool tokens from the user
    * @param numberOfPoolTokens Number of pool tokens to withdraw
    */
    function withdraw(uint numberOfPoolTokens) public override {
        require(numberOfPoolTokens > 0, "Pool: number of pool tokens must be greater than 0");
        require(balanceOf(msg.sender) >= numberOfPoolTokens, "Pool: Not enough pool tokens to withdraw");

        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        uint poolValue = getPoolValue();
        uint userValue = balanceOf(msg.sender).mul(poolValue).div(totalSupply());
        uint valueWithdrawn = poolValue.mul(numberOfPoolTokens).div(totalSupply());
        uint unrealizedProfits = (userValue > userDeposits[msg.sender]) ? userValue.sub(userDeposits[msg.sender]) : 0;

        unrealizedProfits = unrealizedProfits.mul(numberOfPoolTokens).div(balanceOf(msg.sender));
        collectedManagerFees = collectedManagerFees.add(unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).div(valueWithdrawn).div(10000));
        totalDeposits = totalDeposits.sub(userDeposits[msg.sender].mul(numberOfPoolTokens).div(balanceOf(msg.sender)));
        userDeposits[msg.sender] = userDeposits[msg.sender].sub(userDeposits[msg.sender].mul(numberOfPoolTokens).div(balanceOf(msg.sender)));

        //Burn user's pool tokens
        _burn(msg.sender, numberOfPoolTokens);

        uint[] memory amountsWithdrawn = new uint[](addresses.length);

        //Withdraw user's portion of pool's assets
        for (uint i = 0; i < addresses.length; i++)
        {
            uint portionOfAssetBalance = _withdrawProcessing(addresses[i], numberOfPoolTokens.mul(10**18).div(totalSupply()));
            uint fee = unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).mul(portionOfAssetBalance).div(valueWithdrawn).div(10000);

            if (portionOfAssetBalance > 0)
            {
                IERC20(addresses[i]).safeTransfer(manager, fee);
                IERC20(addresses[i]).safeTransfer(msg.sender, portionOfAssetBalance.sub(fee));
                amountsWithdrawn[i] = portionOfAssetBalance;
            }
        }

        emit Withdraw(address(this), msg.sender, numberOfPoolTokens, valueWithdrawn, addresses, amountsWithdrawn);
    }

    /**
    * @dev Withdraws the user's full investment
    */
    function exit() external override {
        withdraw(balanceOf(msg.sender));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Executes a transaction on behalf of the pool; lets pool talk to other protocols
    * @param to Address of external contract
    * @param data Bytes data for the transaction
    */
    function executeTransaction(address to, bytes memory data) external onlyPoolManager {
        require(to != address(0), "Pool: invalid 'to' address");

        //First try to get contract verifier
        address verifier = ADDRESS_RESOLVER.contractVerifiers(to);
        //Try to get asset verifier if no contract verifier found
        if (verifier == address(0))
        {
            address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
            verifier = IAssetHandler(assetHandlerAddress).getVerifier(to);

            //'to' address is an asset; need to check if asset is valid
            if (verifier != address(0))
            {
                require(IAssetHandler(assetHandlerAddress).isValidAsset(to), "Pool: invalid asset");
            }
        }
        
        require(verifier != address(0), "Pool: invalid verifier");
        
        (bool valid, address receivedAsset) = IVerifier(verifier).verify(address(ADDRESS_RESOLVER), address(this), to, data);
        require(valid, "Pool: invalid transaction");
        require(POOL_MANAGER_LOGIC.isAvailableAsset(receivedAsset), "Pool: received asset is not available.");
        
        (bool success, ) = to.call(data);
        require(success, "Pool: transaction failed to execute");

        emit ExecutedTransaction(address(this), manager, to, success);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Performs additional processing when withdrawing an asset (such as checking for staked tokens)
    * @param asset Address of asset to withdraw
    * @param portion User's portion of pool's asset balance
    * @return Amount of tokens to withdraw
    */
    function _withdrawProcessing(address asset, uint portion) internal returns (uint) {
        address verifier = IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).getVerifier(asset);

        (address withdrawAsset, uint withdrawBalance, IAssetVerifier.MultiTransaction[] memory transactions) = IAssetVerifier(verifier).prepareWithdrawal(address(this), asset, portion);

        if (transactions.length > 0)
        {
            uint initialAssetBalance = (withdrawAsset != address(0)) ? IERC20(withdrawAsset).balanceOf(address(this)) : 0;

            //Execute each transaction
            for (uint i = 0; i < transactions.length; i++)
            {
                (bool success,) = (transactions[i].to).call(transactions[i].txData);
                require(success, "Pool: failed to withdraw tokens");
            }

            //Account for additional tokens added (withdrawing staked LP tokens)
            if (withdrawAsset != address(0))
            {
                withdrawBalance = withdrawBalance.add(IERC20(withdrawAsset).balanceOf(address(this))).sub(initialAssetBalance);
            }
        }

        return withdrawBalance;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyPoolManager() {
        require(msg.sender == manager, "Pool: Only pool's manager can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(address indexed poolAddress, address indexed userAddress, uint amount, uint userUSDValue);
    event Withdraw(address indexed poolAddress, address indexed userAddress, uint numberOfPoolTokens, uint valueWithdrawn, address[] assets, uint[] amountsWithdrawn);
    event ExecutedTransaction(address indexed poolAddress, address indexed manager, address to, bool success);
}