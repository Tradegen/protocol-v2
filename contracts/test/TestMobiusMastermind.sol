// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

contract TestMobiusMastermind {

    mapping (uint256 => mapping (address => uint256)) public pendingNerve;
    uint256 public amount;

    struct UserInfo {
        uint256 amount;
        uint256 debt;
    }

    constructor() {}

    function setPendingNerve(uint256 _pid, address _account, uint256 _amount) external {
        pendingNerve[_pid][_account] = _amount;
    }

    function setAmount(uint256 _amount) external {
        amount = _amount;
    }

    function userInfo(uint256, address) external view returns (UserInfo memory) {
        return UserInfo(amount, 0);
    }
}

