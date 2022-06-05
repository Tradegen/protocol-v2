// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Libraries.
import "../../libraries/Bytes.sol";
import "../../openzeppelin-solidity/contracts/SafeMath.sol";

// Inheritance.
import "../../interfaces/IAssetVerifier.sol";
import "../../interfaces/IVerifier.sol";

// Internal references.
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IAssetHandler.sol";
import "../../interfaces/IERC20.sol";

contract ERC20Verifier is IVerifier, IAssetVerifier {
    using SafeMath for uint256;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Parses the transaction data to make sure the transaction is valid.
    * @param _pool Address of the pool.
    * @param _to Address of the external contract.
    * @param _data Transaction call data.
    * @return (bool, address, uint256) Whether the transaction is valid, the received asset, and the transaction type.
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
            require(verifier != address(0), "ERC20Verifier: Unsupported spender approval."); 

            emit Approve(_pool, spender, amount);

            return (true, _to, 1);
        }

        return (false, address(0), 0);
    }

    /**
    * @notice Creates transaction data for withdrawing tokens.
    * @param _pool Address of the pool.
    * @param _asset Address of the asset.
    * @param _portion Portion of the pool's balance in the asset.
    * @return (WithdrawalData) A struct containing the asset withdrawn, amount of asset withdrawn, and the transactions used to execute the withdrawal.
    */
    function prepareWithdrawal(address _pool, address _asset, uint256 _portion) external view virtual override returns (WithdrawalData memory) {
        return WithdrawalData({
            withdrawalAsset: _asset,
            withdrawalAmount: getBalance(_pool, _asset).mul(_portion).div(10**18),
            externalAddresses: new address[](0),
            transactionDatas: new bytes[](0)
        });
    }

    /**
    * @notice Returns the pool's balance in the asset.
    * @param _pool Address of the pool.
    * @param _asset Address of the asset.
    * @return uint256 Pool's balance in the asset.
    */
    function getBalance(address _pool, address _asset) public view virtual override returns (uint256) {
        return IERC20(_asset).balanceOf(_pool);
    }

    /**
    * @notice Returns the decimals of the asset.
    * @param _asset Address of the asset.
    * @return uint256 Asset's number of decimals.
    */
    function getDecimals(address _asset) external view override returns (uint256) {
        return IERC20(_asset).decimals();
    }

    /* ========== EVENTS ========== */

    event Approve(address pool, address spender, uint256 amount);
}