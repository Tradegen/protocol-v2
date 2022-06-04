// SPDX-License-Identifier: MIT

// Interfaces.
import '../interfaces/ICappedPoolNFT.sol';

pragma solidity ^0.8.3;

contract TestCappedPool {

    address public cappedPoolNFT;

    constructor() {}

    function setNFT(address _cappedPoolNFT) external {
        cappedPoolNFT = _cappedPoolNFT;
    }

    // Price is $2.
    function tokenPrice() external view returns (uint256) {
        return 2e18;
    }

    function depositByClass(address _user, uint256 _numberOfTokens, uint256 _amountOfUSD) external {
        ICappedPoolNFT(cappedPoolNFT).depositByClass(_user, _numberOfTokens, _amountOfUSD);
    }

    function burnTokens(address _user, uint256 _tokenClass, uint256 _numberOfTokens) external {
        ICappedPoolNFT(cappedPoolNFT).burnTokens(_user, _tokenClass, _numberOfTokens);
    }
}