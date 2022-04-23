// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestStakingRewards {

    mapping (address => uint256) public override earned;

    constructor() {}

    function setEarned(address _account, uint256 _earned) external {
        earned[_account] = _earned;
    }
}