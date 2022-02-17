// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Libraries
import "../../libraries/TxDataUtils.sol";
import "../../openzeppelin-solidity/contracts/SafeMath.sol";

//Inheritance
import "./ERC20Verifier.sol";

//Internal references
import "../../interfaces/IMoolaAdapter.sol";

contract MoolaInterestBearingTokenVerifier is ERC20Verifier {
    using SafeMath for uint;

    /* ========== VIEWS ========== */

    /**
    * @dev Parses the transaction data to make sure the transaction is valid
    * @param addressResolver Address of AddressResolver contract
    * @param pool Address of the pool
    * @param to External contract address
    * @param data Transaction call data
    * @return (uint, address) Whether the transaction is valid and the received asset
    */
    function verify(address addressResolver, address pool, address to, bytes calldata data) external virtual override returns (bool, address) {
        bytes4 method = getMethod(data);

        if (method == bytes4(keccak256("approve(address,uint256)")))
        {
            address spender = convert32toAddress(getInput(data, 0));
            uint amount = uint(getInput(data, 1));

            //Only check for contract verifier, since an asset probably won't call transferFrom() on another asset
            address verifier = IAddressResolver(addressResolver).contractVerifiers(spender);

            //Checks if the spender is an approved address
            require(verifier != address(0), "MoolaInterestBearingTokenVerifier: unsupported spender approval"); 

            emit Approve(pool, spender, amount);

            return (true, address(0));
        }
        else if (method == bytes4(keccak256("redeem(uint256)")))
        {
            uint amount = uint(getInput(data, 0));

            address assetHandlerAddress = IAddressResolver(addressResolver).getContractAddress("AssetHandler");
            address moolaAdapterAddress = IAddressResolver(addressResolver).getContractAddress("MoolaAdapter");
            address underlyingAsset = IMoolaAdapter(moolaAdapterAddress).getUnderlyingAsset(to);

            require(IAssetHandler(assetHandlerAddress).isValidAsset(underlyingAsset), "MoolaInterestBearingTokenVerifier: unsupported underlying asset.");

            emit Redeem(pool, to, amount);

            return (true, address(0));
        }

        return (false, address(0));
    }

    /* ========== EVENTS ========== */

    event Redeem(address indexed pool, address indexed interestBearingToken, uint amount);
}