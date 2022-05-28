// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library Bytes {
  /**
  * @notice Slices the given bytes.
  * @param _bytes Bytes data to slice.
  * @param _start Index in bytes data to begin slicing from.
  * @param _length Number of bytes to slice.
  * @return bytes The sliced bytes.
  */
  function slice(bytes memory _bytes, uint256 _start, uint256 _length) public pure returns (bytes memory) {
    require(_length + 31 >= _length, "Bytes: Overflow.");
    require(_start + _length >= _start, "Bytes: Overflow.");
    require(_bytes.length >= _start + _length, "Bytes: Slice out of bounds.");

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
        case 0 {
          // Get a location of some free memory and store it in tempBytes as
          // Solidity does for memory variables.
          tempBytes := mload(0x40)

          // The first word of the slice result is potentially a partial
          // word read from the original array. To read it, we calculate
          // the length of that partial word and start copying that many
          // bytes into the array. The first word we copy will start with
          // data we don't care about, but the last `lengthmod` bytes will
          // land at the beginning of the contents of the new array. When
          // we're done copying, we overwrite the full first word with
          // the actual length of the slice.
          let lengthmod := and(_length, 31)

          // The multiplication in the next line is necessary
          // because when slicing multiples of 32 bytes (lengthmod == 0)
          // the following copy loop was copying the origin's length
          // and then ending prematurely not copying everything it should.
          let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
          let end := add(mc, _length)

          for {
            // The multiplication in the next line has the same exact purpose
            // as the one above.
            let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
          } lt(mc, end) {
            mc := add(mc, 0x20)
            cc := add(cc, 0x20)
          } {
            mstore(mc, mload(cc))
          }

          mstore(tempBytes, _length)

          // Update free-memory pointer.
          // Allocating the array padded to 32 bytes like the compiler does now.
          mstore(0x40, and(add(mc, 31), not(31)))
        }
        // If we want a zero-length slice let's just return a zero-length array.
        default {
          tempBytes := mload(0x40)
          // Zero out the 32 bytes slice we are about to return.
          // We need to do it because Solidity does not garbage collect.
          mstore(tempBytes, 0)

          mstore(0x40, add(tempBytes, 0x20))
        }
    }

    return tempBytes;
  }

  /**
  * @notice Converts the given bytes to an address.
  * @param _bytes Bytes data to convert.
  * @param _start Index in the bytes data to begin converting.
  * @return address The bytes data converted to an address.
  */
  function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
    require(_start + 20 >= _start, "Bytes: Overflow.");
    require(_bytes.length >= _start + 20, "Bytes: Out of bounds.");

    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  /**
  * @notice Converts the given bytes to a uint24.
  * @param _bytes Bytes data to convert.
  * @param _start Index in the bytes data to begin converting.
  * @return uint24 The bytes data converted to a uint24.
  */
  function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
    require(_start + 3 >= _start, "Bytes: Overflow.");
    require(_bytes.length >= _start + 3, "Bytes: Out of bounds.");

    uint24 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x3), _start))
    }

    return tempUint;
  }

  /**
  * @notice Parses a method name from bytes data.
  * @param _data Bytes data to read from.
  * @return bytes4 The bytes data converted to a method name.
  */
  function getMethod(bytes calldata _data) public pure returns (bytes4) {
    return read4left(_data, 0);
  }

  /**
  * @notice Parses function parameters from bytes data.
  * @param _data Bytes data to read from.
  * @return bytes The bytes data converted to function parameters.
  */
  function getParams(bytes calldata _data) external pure returns (bytes memory) {
    return slice(_data, 4, _data.length - 4);
  }

  /**
  * @notice Given bytes data representing a function signature, returns the parameter at the given index.
  * @param _data Bytes data to read from.
  * @param _inputNum Index in the function signature's parameters.
  *                  Ex) The first parameter has index 0.
  * @return bytes32 The function parameter converted to bytes32.
  */
  function getInput(bytes calldata _data, uint8 _inputNum) public pure returns (bytes32) {
    return read32(_data, 32 * _inputNum + 4, 32);
  }

  /**
  * @notice Reads an array from bytes data representing a function signature.
  * @param _data Bytes data to read from.
  * @param _inputNum Index in the function signature's parameters.
  * @param _offset Number of bytes32 slots.
  * @return bytes The array, represented as bytes.
  */
  function getBytes(bytes calldata _data, uint8 _inputNum, uint256 _offset) public pure returns (bytes memory) {
    // Offset is in byte32 slots, not bytes.
    require(_offset < 20, "Bytes: Invalid offset.");

    // Convert offset to bytes.
    _offset = _offset * 32; 

    uint256 bytesLenPos = uint256(read32(_data, 32 * _inputNum + 4 + _offset, 32));
    uint256 bytesLen = uint256(read32(_data, bytesLenPos + 4 + _offset, 32));

    return slice(_data, bytesLenPos + 4 + _offset + 32, bytesLen);
  }

  /**
  * @notice Returns the last element in an array, represented as bytes.
  * @param _data Bytes data to read from.
  * @param _inputNum Index in the function signature's parameters.
  * @return bytes32 The last element of the array.
  */
  function getArrayLast(bytes calldata _data, uint8 _inputNum) public pure returns (bytes32) {
    bytes32 arrayPos = read32(_data, 32 * _inputNum + 4, 32);
    bytes32 arrayLen = read32(_data, uint256(arrayPos) + 4, 32);

    require(arrayLen > 0, "Bytes: Input is not an array.");

    return read32(_data, uint256(arrayPos) + 4 + (uint256(arrayLen) * 32), 32);
  }

  /**
  * @notice Returns the length of an array, represented as bytes.
  * @param _data Bytes data to read from.
  * @param _inputNum Index in the function signature's parameters.
  * @return uint256 The length of the array.
  */
  function getArrayLength(bytes calldata _data, uint8 _inputNum) external pure returns (uint256) {
    bytes32 arrayPos = read32(_data, 32 * _inputNum + 4, 32);

    return uint256(read32(_data, uint256(arrayPos) + 4, 32));
  }

  /**
  * @notice Returns the data at the given index of an array, represented as bytes.
  * @param _data Bytes data to read from.
  * @param _inputNum Index in the function signature's parameters.
  * @param _arrayIndex Index in the array.
  * @return bytes32 The element at the given index of the array.
  */
  function getArrayIndex(bytes calldata _data, uint8 _inputNum, uint8 _arrayIndex) public pure returns (bytes32) {
    bytes32 arrayPos = read32(_data, 32 * _inputNum + 4, 32);
    bytes32 arrayLen = read32(_data, uint256(arrayPos) + 4, 32);

    require(arrayLen > 0, "Bytes: Input is not array.");
    require(uint256(arrayLen) > _arrayIndex, "Bytes: Invalid array position.");

    return read32(_data, uint256(arrayPos) + 4 + ((1 + uint256(_arrayIndex)) * 32), 32);
  }

  /**
  * @notice Reads 4 bytes, starting at the offset.
  * @param _data Bytes data to read from.
  * @param _offset The byte to start reading from.
  * @return o Parsed bytes4 data.
  */
  function read4left(bytes memory _data, uint256 _offset) public pure returns (bytes4 o) {
    require(_data.length >= _offset + 4, "Bytes: Reading bytes out of bounds.");

    assembly {
      o := mload(add(_data, add(32, _offset)))
    }
  }

  /**
  * @notice Reads [_length] bytes from the given bytes data, starting from the offset.
  * @param _data Bytes data to read from.
  * @param _offset Byte to start from.
  * @param _length Number of bytes to read.
  * @return o Parsed bytes converted to bytes32.
  */
  function read32(bytes memory _data, uint256 _offset, uint256 _length) public pure returns (bytes32 o) {
    require(_data.length >= _offset + _length, "Bytes: Reading bytes out of bounds.");

    assembly {
      o := mload(add(_data, add(32, _offset)))
      let lb := sub(32, _length)
      if lb {
        o := div(o, exp(2, mul(lb, 8)))
      }
    }
  }

  /**
  * @notice Converts the given bytes32 data to an address.
  */
  function convert32toAddress(bytes32 _data) public pure returns (address o) {
    return address(uint160(uint256(_data)));
  }

  /**
  * @notice Slices a uint from the given bytes data, starting from [_start] byte.
  * @param _data Bytes data to read from.
  * @param _start The byte to start from.
  * @return x Parsed bytes converted to uint256.
  */
  function sliceUint(bytes memory _data, uint256 _start) internal pure returns (uint256 x) {
    require(_data.length >= _start + 32, "Bytes: Slicing out of range.");

    assembly {
      x := mload(add(_data, add(0x20, _start)))
    }
  }
}