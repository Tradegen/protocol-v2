// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestMobiusMastermind {

    mapping (uint256 => mapping (address => uint256)) public pendingNerve;

    constructor() {}

    function setPendingNerve(uint256 _pid, address _account, uint256 _amount) external {
        pendingNerve[_pid][_account] = _amount;
    }
}

