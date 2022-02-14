// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Interfaces
import './interfaces/IERC20.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/IAssetVerifier.sol';
import './interfaces/IVerifier.sol';
import './interfaces/IMarketplace.sol';

//Inheritance
import './interfaces/ICappedPool.sol';

//Libraries
import './openzeppelin-solidity/contracts/SafeMath.sol';
import './openzeppelin-solidity/contracts/ERC1155/ERC1155.sol';

contract CappedPool is ICappedPool, ERC1155 {
    using SafeMath for uint;

    IAddressResolver public ADDRESS_RESOLVER;
    address private _factory;
    bool private _initialized;
    address public farm;
   
    //Pool info
    string public name;
    address public manager;
    uint public maxSupply;
    uint public seedPrice;

    //Token class
    uint public availableC1;
    uint public availableC2;
    uint public availableC3;
    uint public availableC4;

    //User pool tokens
    mapping (address => uint) public override balance;
    uint public override totalSupply;

    //Position management
    mapping (uint => address) public _positionKeys;
    uint public numberOfPositions;
    mapping (address => uint) public positionToIndex; //maps to (index + 1), with index 0 representing position not found

    constructor() {
        _factory = msg.sender;
        _initialized = false;
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
        address[] memory addresses = new address[](numberOfPositions);
        uint[] memory balances = new uint[](numberOfPositions);
        uint sum;

        //Calculate USD value of each asset
        for (uint i = 0; i < numberOfPositions; i++)
        {
            balances[i] = IAssetHandler(assetHandlerAddress).getBalance(address(this), _positionKeys[i.add(1)]);
            addresses[i] = _positionKeys[i.add(1)];

            uint numberOfDecimals = IAssetHandler(assetHandlerAddress).getDecimals(_positionKeys[i.add(1)]);
            uint USDperToken = IAssetHandler(assetHandlerAddress).getUSDPrice(_positionKeys[i.add(1)]);
            uint positionBalanceInUSD = balances[i].mul(USDperToken).div(10 ** numberOfDecimals);
            sum = sum.add(positionBalanceInUSD);
        }

        return (addresses, balances, sum);
    }

    /**
    * @dev Returns the amount of cUSD the pool has to invest
    * @return uint Amount of cUSD the pool has available
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
        uint sum = 0;

        //Get USD value of each asset
        for (uint i = 1; i <= numberOfPositions; i++)
        {
            sum = sum.add(getAssetValue(_positionKeys[i], assetHandlerAddress));
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
    * @notice Call cUSD.approve() before calling this function
    * @param numberOfPoolTokens Number of pool tokens to purchase
    */
    function deposit(uint numberOfPoolTokens) public override {
        require(numberOfPoolTokens > 0 &&
                totalSupply.add(numberOfPoolTokens) <= maxSupply,
                "Quantity out of bounds");

        address stableCoinAddress = IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).getStableCoinAddress();
        uint amountOfUSD = tokenPrice().mul(numberOfPoolTokens);

        balance[msg.sender] = balance[msg.sender].add(numberOfPoolTokens);
        totalSupply = totalSupply.add(numberOfPoolTokens);

        _depositByClass(msg.sender, numberOfPoolTokens);

        IERC20(stableCoinAddress).transferFrom(msg.sender, address(this), amountOfUSD);

        emit Deposit(address(this), msg.sender, numberOfPoolTokens, amountOfUSD, block.timestamp);
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

        uint managerFee = ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("MarketplaceAssetManagerFee");

        uint poolValue = getPoolValue();
        uint portion = numberOfPoolTokens.mul(10**18).div(totalSupply);

        //Burn user's pool tokens
        balance[msg.sender] = balance[msg.sender].sub(numberOfPoolTokens);
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

        uint[] memory amountsWithdrawn = new uint[](numberOfPositions);
        address[] memory assetsWithdrawn = new address[](numberOfPositions);

        uint assetCount = numberOfPositions;
        //Withdraw user's portion of pool's assets
        for (uint i = assetCount; i > 0; i--)
        {
            uint portionOfAssetBalance = _withdrawProcessing(_positionKeys[i], portion);

            if (portionOfAssetBalance > 0)
            {
                IERC20(_positionKeys[i]).transfer(msg.sender, portionOfAssetBalance.mul(10000 - managerFee).div(10000));
                IERC20(_positionKeys[i]).transfer(manager, portionOfAssetBalance.mul(managerFee).div(10000));

                amountsWithdrawn[i.sub(1)] = portionOfAssetBalance.mul(10000 - managerFee).div(10000);
                assetsWithdrawn[i.sub(1)] = _positionKeys[i];
            }
        }

        uint valueWithdrawn = poolValue.mul(portion).div(10**18);

        emit Withdraw(address(this), msg.sender, numberOfPoolTokens, valueWithdrawn, assetsWithdrawn, amountsWithdrawn, block.timestamp);
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

    /* ========== RESTRICTED FUNCTIONS ========== */

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
        
        (bool success, ) = to.call(data);
        require(success, "Transaction failed to execute");

        emit ExecutedTransaction(address(this), manager, to, success, block.timestamp);
    }

    /**
    * @dev Initializes the pool's data and distributes tokens by class
    * @notice Meant to be called once from CappedPoolFactory contract
    * @notice Token distribution: 5% C1, 10% C2, 20% C3, 65% C4
    * @param poolName Name of the pool
    * @param price Initial token price
    * @param supplyCap Maximum number of tokens the pool can have
    * @param poolManager Address of the user who managed this pool
    * @param addressResolver Instance of AddressResolver interface
    */
    function initialize(string memory poolName, uint price, uint supplyCap, address poolManager, IAddressResolver addressResolver) external onlyFactory notInitialized {
        name = poolName;
        manager = poolManager;
        seedPrice = price;
        maxSupply = supplyCap;
        ADDRESS_RESOLVER = addressResolver;

        _initialized = true;

        availableC1 = (supplyCap.mul(5).div(100) > 1) ? supplyCap.mul(5).div(100) : 1;
        availableC2 = (supplyCap.mul(10).div(100) > 2) ? supplyCap.mul(10).div(100) : 2;
        availableC3 = (supplyCap.mul(20).div(100) > 3) ? supplyCap.mul(20).div(100) : 3;
        availableC4 = supplyCap.sub(availableC3).sub(availableC2).sub(availableC1);
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

    function setFarmAddress(address farmAddress) external onlyOperator {
        farm = farmAddress;
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

    modifier notInitialized() {
        require(!_initialized, "CappedPool: Already initialized");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("Operator"), "CappedPool: Only Operator can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(address indexed poolAddress, address indexed userAddress, uint numberOfPoolTokens, uint amountOfUSD, uint timestamp);
    event Withdraw(address indexed poolAddress, address indexed userAddress, uint numberOfPoolTokens, uint valueWithdrawn, address[] assets, uint[] amountsWithdrawn, uint timestamp);
    event ExecutedTransaction(address indexed poolAddress, address indexed manager, address to, bool success, uint timestamp);
}