// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ICappedPoolNFT {
    /**
    * @notice Returns the user's cost basis.
    */
    function userDeposits(address _user) external view returns (uint256);

    /**
    * @notice Returns the total cost basis of the pool.
    */
    function totalDeposits() external view returns (uint256);

    /**
    * @notice Returns the number of tokens available for each class.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getAvailableTokensPerClass() external view returns (uint256, uint256, uint256, uint256);

    /**
    * @notice Returns the number of tokens the given user has for each class.
    * @param _user Address of the user.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getTokenBalancePerClass(address _user) external view returns (uint256, uint256, uint256, uint256);

    /**
    * @notice Distributes user's deposit into different token classes based on how many tokens are available for each class.
    * @dev Attempt to distribute C1 first and work up to C4.
    * @dev This function can only be called by the CappedPool contract.
    * @param _user Address of the user.
    * @param _numberOfTokens Total number of tokens to distribute to the user.
    * @param _amountOfUSD Amount of USD to add to the cost basis.
    * @return uint256 The total cost basis of the pool.
    */
    function depositByClass(address _user, uint256 _numberOfTokens, uint256 _amountOfUSD) external returns (uint256);

    /**
    * @notice Burns the user's tokens for the given class.
    * @dev This function can only be called by the CappedPool contract.
    * @param _user Address of the user.
    * @param _tokenClass The class (C1 - C4) of the token.
    * @param _numberOfTokens Number of tokens to burn for the given class.
    * @return uint256 The total cost basis of the pool.
    */
    function burnTokens(address _user, uint256 _tokenClass, uint256 _numberOfTokens) external returns (uint256);

    /**
    * @notice Returns the total number of tokens the user has across token classes.
    * @param _user Address of the user.
    * @return uint256 Total number of tokens the user has.
    */
    function balance(address _user) external view returns (uint256);

    /**
    * @notice Returns the total supply of pool tokens.
    */
    function totalSupply() external view returns (uint256);
}