// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Interfaces
import './interfaces/ISettings.sol';
import './interfaces/IPoolManagerLogic.sol';
import './interfaces/IPoolManager.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/IAssetVerifier.sol';
import './interfaces/IVerifier.sol';

//Inheritance
import './interfaces/ICappedPool.sol';

//Libraries
import './openzeppelin-solidity/contracts/SafeMath.sol';
import './openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';
import './openzeppelin-solidity/contracts/ERC1155/ERC1155.sol';

contract CappedPool is ICappedPool, ERC1155 {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IAddressResolver public ADDRESS_RESOLVER;
    IPoolManagerLogic public POOL_MANAGER_LOGIC;
    IPoolManager public immutable POOL_MANAGER;

    address private _factory;
   
    //Pool info
    string public name;
    address public override manager;
    uint public maxSupply;
    uint public seedPrice;
    uint256 public collectedManagerFees;

    //Token class
    uint public availableC1;
    uint public availableC2;
    uint public availableC3;
    uint public availableC4;

    //User pool tokens
    mapping (address => uint) public override balance;
    uint public override totalSupply;

    mapping (address => uint256) public userDeposits;
    uint256 public totalDeposits;
    uint256 public unrealizedProfitsAtLastSnapshot;
    uint256 public timestampAtLastSnapshot;

    /**
    * @dev Initializes the pool's data and distributes tokens by class
    * @notice Meant to be called once from CappedPoolFactory contract
    * @notice Token distribution: 5% C1, 10% C2, 20% C3, 65% C4
    * @param _poolName Name of the pool
    * @param _seedPrice Initial token price
    * @param _supplyCap Maximum number of tokens the pool can have
    * @param _manager Address of the user who manages this pool
    * @param _addressResolver Address of the AddressResolver contract
    * @param _poolManager Address of the PoolManager contract
    */
    constructor(string memory _poolName, uint _seedPrice, uint _supplyCap, address _manager, address _addressResolver, address _poolManager) {
        _factory = msg.sender;
        name = _poolName;
        manager = _manager;
        seedPrice = _seedPrice;
        maxSupply = _supplyCap;
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
        POOL_MANAGER = IPoolManager(_poolManager);

        availableC1 = (_supplyCap.mul(5).div(100) > 1) ? _supplyCap.mul(5).div(100) : 1;
        availableC2 = (_supplyCap.mul(10).div(100) > 2) ? _supplyCap.mul(10).div(100) : 2;
        availableC3 = (_supplyCap.mul(20).div(100) > 3) ? _supplyCap.mul(20).div(100) : 3;
        availableC4 = _supplyCap.sub(availableC3).sub(availableC2).sub(availableC1);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the number of tokens available for each class
    * @return (uint, uint, uint, uint) Number of available C1, C2, C3, and C4 tokens
    */
    function getAvailableTokensPerClass() external view override returns(uint, uint, uint, uint) {
        return (availableC1, availableC2, availableC3, availableC4);
    }

    /**
    * @dev Given the address of a user, returns the number of tokens the user has for each class
    * @param user Address of the user
    * @return (uint, uint, uint, uint) Number of available C1, C2, C3, and C4 tokens
    */
    function getTokenBalancePerClass(address user) external view override returns(uint, uint, uint, uint) {
        require(user != address(0), "Invalid user address");

        return (balanceOf(user, 1), balanceOf(user, 2), balanceOf(user, 3), balanceOf(user, 4));
    }

    /**
    * @dev Returns the USD value of the asset
    * @param asset Address of the asset
    * @param assetHandlerAddress Address of AssetHandler contract
    */
    function getAssetValue(address asset, address assetHandlerAddress) public view override returns (uint) {
        require(asset != address(0), "Invalid asset address");
        require(assetHandlerAddress != address(0), "Invalid asset handler address");

        uint USDperToken = IAssetHandler(assetHandlerAddress).getUSDPrice(asset);
        uint numberOfDecimals = IAssetHandler(assetHandlerAddress).getDecimals(asset);
        uint assetBalance = IAssetHandler(assetHandlerAddress).getBalance(address(this), asset);

        return assetBalance.mul(USDperToken).div(10 ** numberOfDecimals);
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

        if (totalSupply == 0)
        {
            return 0;
        }

        uint poolValue = getPoolValue();

        return poolValue.mul(balance[user]).div(totalSupply);
    }

    /**
    * @dev Returns the price of the pool's token
    * @return USD price of the pool's token
    */
    function tokenPrice() public view override returns (uint) {
        uint poolValue = getPoolValue();

        return _tokenPrice(poolValue);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Purchases the given amount of pool tokens
    * @notice Call depositAsset.approve() before calling this function
    * @param _numberOfPoolTokens Number of pool tokens to purchase
    * @param _depositAsset Address of the asset to deposit
    */
    function deposit(uint _numberOfPoolTokens, address _depositAsset) public override {
        require(POOL_MANAGER_LOGIC.isDepositAsset(_depositAsset), "Pool: asset is not available to deposit.");
        require(_numberOfPoolTokens > 0 &&
                totalSupply.add(_numberOfPoolTokens) <= maxSupply,
                "Quantity out of bounds");

        uint poolValue = getPoolValue();
        uint USDperDepositAssetToken = IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).getUSDPrice(_depositAsset);
        uint amountOfUSD = tokenPrice().mul(_numberOfPoolTokens);

        balance[msg.sender] = balance[msg.sender].add(_numberOfPoolTokens);
        totalSupply = totalSupply.add(_numberOfPoolTokens);
        userDeposits[msg.sender] = userDeposits[msg.sender].add(amountOfUSD);
        totalDeposits = totalDeposits.add(amountOfUSD);

        _depositByClass(msg.sender, _numberOfPoolTokens);

        IERC20(_depositAsset).safeTransferFrom(msg.sender, address(this), amountOfUSD.div(USDperDepositAssetToken));

        POOL_MANAGER.updateWeight(poolValue > totalDeposits ? poolValue.sub(totalDeposits) : 0, _tokenPrice(poolValue));

        emit Deposit(address(this), msg.sender, _numberOfPoolTokens, amountOfUSD, _depositAsset, amountOfUSD.div(USDperDepositAssetToken));
    }

    /**
    * @dev Withdraws the user's full investment
    * @param numberOfPoolTokens Number of pool tokens to withdraw
    * @param tokenClass Token class to withdraw from
    */
    function withdraw(uint numberOfPoolTokens, uint tokenClass) public override {
        require(tokenClass > 0 && tokenClass < 5, "Token class must be between 1 and 4");
        require(numberOfPoolTokens > 0,
                "Withdrawal amount must be greater than 0");
        require(numberOfPoolTokens <= balanceOf(msg.sender, tokenClass),
                 "Not enough tokens");

        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        uint poolValue = getPoolValue();
        uint userValue = balance[msg.sender].mul(poolValue).div(totalSupply);
        uint valueWithdrawn = poolValue.mul(numberOfPoolTokens).div(totalSupply);
        uint unrealizedProfits = (userValue > userDeposits[msg.sender]) ? userValue.sub(userDeposits[msg.sender]) : 0;

        unrealizedProfits = unrealizedProfits.mul(numberOfPoolTokens).div(balance[msg.sender]);
        collectedManagerFees = collectedManagerFees.add(unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).div(valueWithdrawn).div(10000));
        totalDeposits = totalDeposits.sub(userDeposits[msg.sender].mul(numberOfPoolTokens).div(balance[msg.sender]));
        userDeposits[msg.sender] = userDeposits[msg.sender].sub(userDeposits[msg.sender].mul(numberOfPoolTokens).div(balance[msg.sender]));

        //Burn user's pool tokens
        balance[msg.sender] = balance[msg.sender].sub(numberOfPoolTokens);
        totalSupply = totalSupply.sub(numberOfPoolTokens);
        _burn(msg.sender, tokenClass, numberOfPoolTokens);

        //Update number of available tokens per class
        if (tokenClass == 1)
        {
            availableC1 = availableC1.add(numberOfPoolTokens);
        }
        else if (tokenClass == 2)
        {
            availableC2 = availableC2.add(numberOfPoolTokens);
        }
        else if (tokenClass == 3)
        {
            availableC3 = availableC3.add(numberOfPoolTokens);
        }
        else if (tokenClass == 4)
        {
            availableC4 = availableC4.add(numberOfPoolTokens);
        }

        uint[] memory amountsWithdrawn = new uint[](addresses.length);

        //Withdraw user's portion of pool's assets
        for (uint i = 0; i < addresses.length; i++)
        {
            uint portionOfAssetBalance = _withdrawProcessing(addresses[i], numberOfPoolTokens.mul(10**18).div(totalSupply));
            uint fee = unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).mul(portionOfAssetBalance).div(valueWithdrawn).div(10000);

            if (portionOfAssetBalance > 0)
            {
                IERC20(addresses[i]).safeTransfer(manager, fee);
                IERC20(addresses[i]).safeTransfer(msg.sender, portionOfAssetBalance.sub(fee));
                amountsWithdrawn[i] = portionOfAssetBalance;
            }
        }

        POOL_MANAGER.updateWeight(poolValue > totalDeposits ? poolValue.sub(totalDeposits) : 0, _tokenPrice(poolValue));

        emit Withdraw(address(this), msg.sender, numberOfPoolTokens, valueWithdrawn, addresses, amountsWithdrawn);
    }

    /**
    * @dev Withdraws the user's full investment
    */
    function exit() external override {
        for (uint i = 1; i <= 4; i++)
        {
            if (balanceOf(msg.sender, i) > 0)
            {
                withdraw(balanceOf(msg.sender, i), i);
            }
        }
    }

    /**
    * @dev Transfers tokens from seller to buyer
    * @param from Address of the seller
    * @param to Address of the buyer
    * @param id The class of the asset's token; in range [1, 4]
    * @param amount Number of tokens to transfer for the given class
    * @param data Bytes data
    */
    function safeTransferFrom(address from, address to, uint id, uint amount, bytes memory data) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        balance[from] = balance[from].sub(amount);
        balance[to] = balance[to].add(amount);

        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public override {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setPoolManagerLogic(address _poolManagerLogicAddress) external override onlyFactory {
        require(_poolManagerLogicAddress != address(0), "Pool: invalid asset address");
        require(address(POOL_MANAGER_LOGIC) == address(0), "Pool: already set pool manager logic.");

        POOL_MANAGER_LOGIC = IPoolManagerLogic(_poolManagerLogicAddress);

        emit SetPoolManagerLogic(address(this), _poolManagerLogicAddress);
    }

    /**
    * @dev Updates the pool's weight in the farming system based on its current unrealized profits and token price.
    */
    function takeSnapshot() external onlyPoolManager {
        uint256 poolValue = getPoolValue();
        uint256 unrealizedProfits = (poolValue > totalDeposits) ? poolValue.sub(totalDeposits) : 0;

        require(unrealizedProfits > unrealizedProfitsAtLastSnapshot, "Pool: unrealized profits decreased from last snapshot.");
        require(block.timestamp.sub(timestampAtLastSnapshot) >= ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("TimeBetweenFeeSnapshots"), "Pool: not enough time between snapshots.");

        unrealizedProfitsAtLastSnapshot = unrealizedProfits;
        timestampAtLastSnapshot = block.timestamp;

        POOL_MANAGER.updateWeight(unrealizedProfits, _tokenPrice(poolValue));

        emit TakeSnapshot(address(this), unrealizedProfits);
    }

    /**
    * @dev Executes a transaction on behalf of the pool; lets pool talk to other protocols
    * @param to Address of external contract
    * @param data Bytes data for the transaction
    */
    function executeTransaction(address to, bytes memory data) public onlyPoolManager {
        require(to != address(0), "Invalid 'to' address");

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
                require(IAssetHandler(assetHandlerAddress).isValidAsset(to), "CappedPool: invalid asset");
            }
        }
        
        require(verifier != address(0), "Invalid verifier");
        
        (bool valid, address receivedAsset) = IVerifier(verifier).verify(address(ADDRESS_RESOLVER), address(this), to, data);
        require(valid, "Invalid transaction");
        require(POOL_MANAGER_LOGIC.isAvailableAsset(receivedAsset), "Pool: received asset is not available.");
        
        (bool success, ) = to.call(data);
        require(success, "Transaction failed to execute");

        uint256 poolValue = getPoolValue();
        POOL_MANAGER.updateWeight(poolValue > totalDeposits ? poolValue.sub(totalDeposits) : 0, _tokenPrice(poolValue));

        emit ExecutedTransaction(address(this), manager, to, success);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Calculates the price of a pool token
    * @param _poolValue Value of the pool in USD
    * @return value Price of a pool token
    */
    function _tokenPrice(uint _poolValue) internal view returns (uint value) {
        value = (_poolValue == 0) ? seedPrice : _poolValue.div(totalSupply);
    }

    /**
    * @dev Performs additional processing when withdrawing an asset (such as checking for staked tokens)
    * @param asset Address of asset to withdraw
    * @param portion User's portion of pool's asset balance
    * @return Amount of tokens to withdraw
    */
    function _withdrawProcessing(address asset, uint portion) internal returns (uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address verifier = IAssetHandler(assetHandlerAddress).getVerifier(asset);

        (address withdrawAsset, uint withdrawBalance, IAssetVerifier.MultiTransaction[] memory transactions) = IAssetVerifier(verifier).prepareWithdrawal(address(this), asset, portion);

        if (transactions.length > 0)
        {
            uint initialAssetBalance;
            if (withdrawAsset != address(0))
            {
                initialAssetBalance = IERC20(withdrawAsset).balanceOf(address(this));
            }

            //Execute each transaction
            for (uint i = 0; i < transactions.length; i++)
            {
                (bool success,) = (transactions[i].to).call(transactions[i].txData);
                require(success, "Failed to withdraw tokens");
            }

            //Account for additional tokens added (withdrawing staked LP tokens)
            if (withdrawAsset != address(0))
            {
                withdrawBalance = withdrawBalance.add(IERC20(withdrawAsset).balanceOf(address(this))).sub(initialAssetBalance);
            }
        }

        return withdrawBalance;
    }

    /**
    * @dev Distributes user's deposit into different token classes based on how many tokens are available for each class
    * @notice Attempt to distribute C1 first and work up to C4
    * @param _user Address of the user
    * @param _numberOfTokens Number of tokens to distribute
    */
    function _depositByClass(address _user, uint _numberOfTokens) internal {
        uint amount;

        if (availableC1 > 0 && _numberOfTokens > 0)
        {
            amount = (_numberOfTokens > availableC1) ? availableC1 : _numberOfTokens;
            _mint(_user, 1, amount, "");
            availableC1 = availableC1.sub(amount);
            _numberOfTokens = _numberOfTokens.sub(amount);
        }

        if (availableC2 > 0 && _numberOfTokens > 0)
        {
            amount = (_numberOfTokens > availableC2) ? availableC2 : _numberOfTokens;
            _mint(_user, 2, amount, "");
            availableC2 = availableC2.sub(amount);
            _numberOfTokens = _numberOfTokens.sub(amount);
        }

        if (availableC3 > 0 && _numberOfTokens > 0)
        {
            amount = (_numberOfTokens > availableC3) ? availableC3 : _numberOfTokens;
            _mint(_user, 3, amount, "");
            availableC3 = availableC3.sub(amount);
            _numberOfTokens = _numberOfTokens.sub(amount);
        }

        if (availableC4 > 0 && _numberOfTokens > 0)
        {
            amount = (_numberOfTokens > availableC4) ? availableC4 : _numberOfTokens;
            _mint(_user, 4, amount, "");
            availableC4 = availableC4.sub(amount);
            _numberOfTokens = _numberOfTokens.sub(amount);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyPoolManager() {
        require(msg.sender == manager, "CappedPool: Only pool's manager can call this function");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == _factory, "CappedPool: Only CappedPoolFactory can call this function");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("Operator"), "CappedPool: Only Operator can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(address indexed poolAddress, address indexed userAddress, uint numberOfPoolTokens, uint amountOfUSD, address depositAsset, uint tokensDeposited);
    event Withdraw(address indexed poolAddress, address indexed userAddress, uint numberOfPoolTokens, uint valueWithdrawn, address[] assets, uint[] amountsWithdrawn);
    event ExecutedTransaction(address indexed poolAddress, address indexed manager, address to, bool success);
    event SetPoolManagerLogic(address indexed poolAddress, address poolManagerLogicAddress);
    event TakeSnapshot(address indexed poolAddress, uint unrealizedProfits);
}