// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestStakingRewards {

    mapping (address => uint256) public earned;
    mapping (address => uint256) public balanceOf;

    constructor() {}

    function setEarned(address _account, uint256 _earned) external {
        earned[_account] = _earned;
    }

    function setBalanceOf(address _account, uint256 _balance) external {
        balanceOf[_account] = _balance;
    }
}