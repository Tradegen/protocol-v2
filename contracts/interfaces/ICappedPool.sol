// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface ICappedPool {
    struct WithdrawVars {
        uint256 poolValue;
        uint256 totalDeposits;
        uint256 userValue;
        uint256 valueWithdrawn;
        uint256 unrealizedProfits;
    }

    /**
    * @notice Returns the address of the pool's CappedPoolNFT contract.
    */
    function getNFTAddress() external view returns (address);
    /**
    * @notice Return the pool manager's address.
    * @return address Address of the pool's manager.
    */
    function manager() external view returns (address);
    
    /**
    * @notice Returns the currency address and balance of each position the pool has, as well as the cumulative value.
    * @return (address[], uint256[], uint256) Currency address and balance of each position the pool has, and the cumulative value of positions.
    */
    function getPositionsAndTotal() external view returns (address[] memory, uint256[] memory, uint256);

    /**
    * @notice Returns the value of the pool in USD.
    */
    function getPoolValue() external view returns (uint256);

    /**
    * @notice Purchases the given amount of pool tokens.
    * @dev Call depositAsset.approve() before calling this function.
    * @param _numberOfPoolTokens Number of pool tokens to purchase.
    * @param _depositAsset Address of the asset to deposit.
    */
    function deposit(uint256 _numberOfPoolTokens, address _depositAsset) external;

    /**
    * @notice Withdraws the user's full investment.
    * @param _numberOfPoolTokens Number of pool tokens to withdraw.
    * @param _tokenClass Class (1 - 4) of the tokens being withdrawn.
    */
    function withdraw(uint256 _numberOfPoolTokens, uint256 _tokenClass) external;

    /**
    * @notice Returns the pool's USD value of the asset.
    * @param _asset Address of the asset.
    * @param _assetHandlerAddress Address of AssetHandler contract.
    * @return uint256 Pool's USD value of the asset.
    */
    function getAssetValue(address _asset, address _assetHandlerAddress) external view returns (uint256);

    /**
    * @notice Returns the mint price of the pool's token.
    */
    function tokenPrice() external view returns (uint256);

    /**
    * @notice Initializes the CappedPoolNFT and PoolManagerLogic contracts.
    * @dev Only the Registry contract can call this function.
    * @dev This function is meant to only be called once, when creating the pool.
    * @param _cappedPoolNFT Address of the CappedPoolNFT contract.
    * @param _poolManagerLogicAddress Address of the PoolManagerLogic contract.
    */
    function initializeContracts(address _cappedPoolNFT, address _poolManagerLogicAddress) external;
}