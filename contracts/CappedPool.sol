// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Interfaces.
import './interfaces/ISettings.sol';
import './interfaces/IPoolManagerLogic.sol';
import './interfaces/farming-system/IPoolManager.sol';
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
import './openzeppelin-solidity/contracts/ERC1155/IERC1155.sol';

contract CappedPool is ICappedPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IAddressResolver ADDRESS_RESOLVER;
    IPoolManagerLogic POOL_MANAGER_LOGIC;
    IPoolManager immutable POOL_MANAGER;
    ICappedPoolNFT CAPPED_POOL_NFT;
   
    // Pool info.
    string public name;
    address public override manager;
    uint256 public maxSupply;
    uint256 public seedPrice;
    uint256 public collectedManagerFees;

    uint256 public unrealizedProfitsAtLastSnapshot;
    uint256 public timestampAtLastSnapshot;

    WithdrawVars private withdrawVars;
    
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
    * @notice Returns the value of the pool in USD.
    */
    function getPoolValue() public view override returns (uint256) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        uint256 sum;

        // Get the USD value of each asset.
        for (uint256 i = 0; i < addresses.length; i++) {
            sum = sum.add(getAssetValue(addresses[i], assetHandlerAddress));
        }
        
        return sum;
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
        require(POOL_MANAGER_LOGIC.isDepositAsset(_depositAsset), "CappedPool: Asset is not available to deposit.");
        require(_numberOfPoolTokens > 0 &&
                CAPPED_POOL_NFT.totalSupply().add(_numberOfPoolTokens) <= maxSupply,
                "CappedPool: Quantity out of bounds.");

        uint256 poolValue = getPoolValue();
        uint256 USDperDepositAssetToken = IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).getUSDPrice(_depositAsset);
        uint256 amountOfUSD = _tokenPrice(poolValue).mul(_numberOfPoolTokens);

        // Mint pool token NFTs and update cost basis.
        uint256 totalDeposits = CAPPED_POOL_NFT.depositByClass(msg.sender, _numberOfPoolTokens, amountOfUSD);

        IERC20(_depositAsset).safeTransferFrom(msg.sender, address(this), amountOfUSD.mul(1e18).div(USDperDepositAssetToken));

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
        withdrawVars.poolValue = getPoolValue();

        {
        address[] memory addresses = POOL_MANAGER_LOGIC.getAvailableAssets();
        withdrawVars.userValue = CAPPED_POOL_NFT.balance(msg.sender).mul(withdrawVars.poolValue).div(CAPPED_POOL_NFT.totalSupply());
        withdrawVars.valueWithdrawn = withdrawVars.poolValue.mul(_numberOfPoolTokens).div(CAPPED_POOL_NFT.totalSupply());
        withdrawVars.unrealizedProfits = (withdrawVars.userValue > CAPPED_POOL_NFT.userDeposits(msg.sender)) ? withdrawVars.userValue.sub(CAPPED_POOL_NFT.userDeposits(msg.sender)) : 0;
        withdrawVars.unrealizedProfits = withdrawVars.unrealizedProfits.mul(_numberOfPoolTokens).div(CAPPED_POOL_NFT.balance(msg.sender));

        collectedManagerFees = collectedManagerFees.add(withdrawVars.unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).div(withdrawVars.valueWithdrawn).div(10000));

        uint256[] memory amountsWithdrawn = new uint256[](addresses.length);

        // Withdraw the user's portion of pool's assets.
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 portionOfAssetBalance = _withdrawProcessing(addresses[i], _numberOfPoolTokens.mul(10**18).div(CAPPED_POOL_NFT.totalSupply()));
            uint256 fee = withdrawVars.unrealizedProfits.mul(POOL_MANAGER_LOGIC.performanceFee()).mul(portionOfAssetBalance).div(withdrawVars.valueWithdrawn).div(10000);

            if (portionOfAssetBalance > 0)
            {
                IERC20(addresses[i]).safeTransfer(manager, fee);
                IERC20(addresses[i]).safeTransfer(msg.sender, portionOfAssetBalance.sub(fee));
                amountsWithdrawn[i] = portionOfAssetBalance;
            }
        }

        emit Withdraw(msg.sender, _numberOfPoolTokens, withdrawVars.valueWithdrawn, addresses, amountsWithdrawn);
        }

        // Burn the user's pool tokens and update cost basis.
        withdrawVars.totalDeposits = CAPPED_POOL_NFT.burnTokens(msg.sender, _tokenClass, _numberOfPoolTokens);

        // Update the pool's weight in the farming system.
        POOL_MANAGER.updateWeight(withdrawVars.poolValue > withdrawVars.totalDeposits ? withdrawVars.poolValue.sub(withdrawVars.totalDeposits) : 0, _tokenPrice(withdrawVars.poolValue));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Initializes the CappedPoolNFT and PoolManagerLogic contracts.
    * @dev Only the Registry contract can call this function.
    * @dev This function is meant to only be called once, when creating the pool.
    * @param _cappedPoolNFT Address of the CappedPoolNFT contract.
    * @param _poolManagerLogicAddress Address of the PoolManagerLogic contract.
    */
    function initializeContracts(address _cappedPoolNFT, address _poolManagerLogicAddress) external override {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("Registry"), "CappedPool: Only Registry contract can call this function.");

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
    * @notice Marks the pool as eligible for farming rewards.
    * @dev Only the pool's manager can call this function.
    * @dev Transaction will revert if the pool was not successfully marked as eligible.
    */
    function markPoolAsEligible() external onlyPoolManager {
        require(POOL_MANAGER.markPoolAsEligible(getPoolValue(), CAPPED_POOL_NFT.numberOfInvestors()), "CappedPool: Could not mark pool as eligible.");

        emit MarkedPoolAsEligible();
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
        return (CAPPED_POOL_NFT.totalSupply() == 0) ? seedPrice : _poolValue.div(CAPPED_POOL_NFT.totalSupply());
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

    /* ========== EVENTS ========== */

    event Deposit(address user, uint256 numberOfPoolTokens, uint256 amountOfUSD, address depositAsset, uint256 tokensDeposited);
    event Withdraw(address user, uint256 numberOfPoolTokens, uint256 valueWithdrawn, address[] assets, uint256[] amountsWithdrawn);
    event ExecutedTransaction(address manager, address to, uint256 transactionType);
    event InitializedContracts(address cappedPoolNFTAddress, address poolManagerLogicAddress);
    event TakeSnapshot(uint256 unrealizedProfits);
    event MarkedPoolAsEligible();
}