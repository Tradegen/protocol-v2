// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Libraries.
import "../../openzeppelin-solidity/contracts/SafeMath.sol";

// Inheritance.
import "./ERC20Verifier.sol";

// Internal references.
import "../../interfaces/IMoolaAdapter.sol";

contract MoolaInterestBearingTokenVerifier is ERC20Verifier {
    using SafeMath for uint256;

    constructor(address _addressResolver) ERC20Verifier(_addressResolver) {}

    /* ========== VIEWS ========== */

    /**
    * @notice Parses the transaction data to make sure the transaction is valid.
    * @param _pool Address of the pool.
    * @param _to Address of the external contract.
    * @param _data Transaction call data.
    * @return (bool, address, uint) Whether the transaction is valid, the received asset, and the transaction type.
    */
    function verify(address _pool, address _to, bytes calldata _data) external virtual override returns (bool, address, uint256) {
        bytes4 method = Bytes.getMethod(_data);

        if (method == bytes4(keccak256("approve(address,uint256)")))
        {
            address spender = Bytes.convert32toAddress(Bytes.getInput(_data, 0));
            uint256 amount = uint256(Bytes.getInput(_data, 1));

            // Only check for contract verifier, since an asset probably won't call transferFrom() on another asset.
            address verifier = ADDRESS_RESOLVER.contractVerifiers(spender);

            // Checks if the spender is an approved address.
            require(verifier != address(0), "MoolaInterestBearingTokenVerifier: Unsupported spender approval."); 

            emit Approve(_pool, spender, amount);

            return (true, address(0), 1);
        }
        else if (method == bytes4(keccak256("redeem(uint256)")))
        {
            uint256 amount = uint256(Bytes.getInput(_data, 0));

            address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
            address moolaAdapterAddress = ADDRESS_RESOLVER.getContractAddress("MoolaAdapter");
            address underlyingAsset = IMoolaAdapter(moolaAdapterAddress).getUnderlyingAsset(_to);

            require(IAssetHandler(assetHandlerAddress).isValidAsset(underlyingAsset), "MoolaInterestBearingTokenVerifier: Unsupported underlying asset.");

            emit Redeem(_pool, _to, amount);

            return (true, address(0), 2);
        }

        return (false, address(0), 0);
    }

    /* ========== EVENTS ========== */

    event Redeem(address pool, address interestBearingToken, uint256 amount);
}