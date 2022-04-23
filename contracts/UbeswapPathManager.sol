// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Inheritance.
import "./openzeppelin-solidity/contracts/Ownable.sol";
import './interfaces/IUbeswapPathManager.sol';

// Interfaces.
import './interfaces/IAssetHandler.sol';
import './interfaces/IAddressResolver.sol';

contract UbeswapPathManager is IUbeswapPathManager, Ownable {
    IAddressResolver public ADDRESS_RESOLVER;

    mapping (address => mapping(address => address[])) public optimalPaths;

    constructor(address _addressResolver) Ownable() {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the path from '_fromAsset' to '_toAsset'.
    * @dev The path is found manually before being stored in this contract.
    * @param _fromAsset Token to swap from.
    * @param _toAsset Token to swap to.
    * @return address[] The pre-determined optimal path from '_fromAsset' to '_toAsset'.
    */
    function getPath(address _fromAsset, address _toAsset) external view override assetIsValid(_fromAsset) assetIsValid(_toAsset) returns (address[] memory) {
        address[] memory path = optimalPaths[_fromAsset][_toAsset];

        require(path.length >= 2, "UbeswapPathManager: Path not found.");

        return path;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Sets the path from '_fromAsset' to '_toAsset'.
    * @dev The path is found manually before being stored in this contract.
    * @dev Only the contract owner can call this function.
    * @param _fromAsset Token to swap from.
    * @param _toAsset Token to swap to.
    * @param _newPath The pre-determined optimal path between the two assets.
    */
    function setPath(address _fromAsset, address _toAsset, address[] memory _newPath) external override onlyOwner assetIsValid(_fromAsset) assetIsValid(_toAsset) {
        require(newPath.length >= 2, "UbeswapPathManager: Path length must be at least 2.");
        require(newPath[0] == _fromAsset, "UbeswapPathManager: First asset in path must be _fromAsset.");
        require(newPath[newPath.length - 1] == _toAsset, "UbeswapPathManager: Last asset in path must be _toAsset.");

        optimalPaths[_fromAsset][_toAsset] = newPath;

        emit SetPath(_fromAsset, _toAsset, newPath);
    }

    /* ========== MODIFIERS ========== */

    modifier assetIsValid(address _assetToCheck) {
        require(_assetToCheck != address(0), "UbeswapPathManager: Asset cannot have zero address.");
        require(IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).isValidAsset(_assetToCheck), "UbeswapPathManager: Asset not supported.");
        _;
    }

    /* ========== EVENTS ========== */

    event SetPath(address fromAsset, address toAsset, address[] newPath);
}