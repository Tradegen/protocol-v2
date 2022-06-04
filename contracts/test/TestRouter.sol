// SPDX-License-Identifier: MIT

import "../openzeppelin-solidity/contracts/ERC20/IERC20.sol";

pragma solidity ^0.8.3;

contract TestRouter {
    uint256 public amount;
    address public token;

    constructor(address _token, _amount) {
        token = _token;
        amount = _amount;
    }

    function swapAssetForTGEN(address, uint256) external {
        IERC20(token).transfer(msg.sender, amount);
    }   
}