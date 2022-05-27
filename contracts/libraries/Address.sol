// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library Address {
  /**
  * @notice Try a contract call via assembly.
  * @param _to Address of the contract.
  * @param _data Call data.
  * @return success Whether the contract call was successful.
  */
  function tryAssemblyCall(address _to, bytes memory _data) internal returns (bool success) {
    assembly {
      success := call(gas(), _to, 0, add(_data, 0x20), mload(_data), 0, 0)
      switch iszero(success)
        case 1 {
          let size := returndatasize()
          returndatacopy(0x00, 0x00, size)
          revert(0x00, size)
        }
    }
  }

  /**
  * @notice Try a contract delegatecall via assembly.
  * @param _to Address of the contract.
  * @param _data Call data.
  * @return success Whether the contract call was successful.
  */
  function tryAssemblyDelegateCall(address _to, bytes memory _data) internal returns (bool success) {
    assembly {
      success := delegatecall(gas(), _to, add(_data, 0x20), mload(_data), 0, 0)
      switch iszero(success)
        case 1 {
          let size := returndatasize()
          returndatacopy(0x00, 0x00, size)
          revert(0x00, size)
        }
    }
  }
}