// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface ICappedPool {
    /**
    * @dev Returns the currency address and balance of each position the pool has, as well as the cumulative value
    * @return (address[], uint[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions
    */
    function getPositionsAndTotal() external view returns (address[] memory, uint[] memory, uint);

    /**
    * @dev Returns the amount of cUSD the pool has to invest
    * @return uint Amount of cUSD in the pool
    */
    function getAvailableFunds() external view returns (uint);

    /**
    * @dev Returns the value of the pool in USD
    * @return uint Value of the pool in USD
    */
    function getPoolValue() external view returns (uint);

    /**
    * @dev Returns the balance of the user in USD
    * @return uint Balance of the user in USD
    */
    function getUSDBalance(address user) external view returns (uint);

    /**
    * @dev Purchases the given amount of pool tokens
    * @notice Call cUSD.approve() before calling this function
    * @param numberOfPoolTokens Number of pool tokens to purchase
    */
    function deposit(uint numberOfPoolTokens) external;

    /**
    * @dev Withdraws the user's full investment
    * @param numberOfPoolTokens Number of pool tokens to withdraw
    * @param tokenClass Token class to withdraw from
    */
    function withdraw(uint numberOfPoolTokens, uint tokenClass) external;

    /**
    * @dev Withdraws the user's full investment
    */
    function exit() external;

    /**
    * @dev Returns the pool's USD value of the asset
    * @param asset Address of the asset
    * @param assetHandlerAddress Address of AssetHandler contract
    * @return uint Pool's USD value of the asset
    */
    function getAssetValue(address asset, address assetHandlerAddress) external view returns (uint);

    /**
    * @dev Returns the supply price of the pool's token
    * @return USD supply price of the pool's token
    */
    function tokenPrice() external view returns (uint);

    /**
    * @dev Returns the total supply of pool tokens
    * @return uint Total supply of pool tokens
    */
    function totalSupply() external view returns (uint);

    /**
    * @dev Returns the number of tokens available for each class
    * @return (uint, uint, uint, uint) Number of available C1, C2, C3, and C4 tokens
    */
    function getAvailableTokensPerClass() external view returns(uint, uint, uint, uint);

    /**
    * @dev Given the address of a user, returns the number of tokens the user has for each class
    * @param user Address of the user
    * @return (uint, uint, uint, uint) Number of available C1, C2, C3, and C4 tokens
    */
    function getTokenBalancePerClass(address user) external view returns(uint, uint, uint, uint);

    /**
    * @dev Returns the total number of tokens the user has across token classes
    * @notice The balance includes tokens the user has for sale
    * @param user Address of the user
    * @return uint Total number of tokens the user has
    */
    function balance(address user) external view returns(uint);
}