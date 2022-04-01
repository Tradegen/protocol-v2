// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Libraries
import "../../libraries/TxDataUtils.sol";
import "../../openzeppelin-solidity/contracts/SafeMath.sol";

//Inheritance
import "../../interfaces/IAssetVerifier.sol";
import "../../interfaces/IVerifier.sol";

//Internal references
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IAssetHandler.sol";
import "../../interfaces/IERC20.sol";

contract ERC20Verifier is TxDataUtils, IVerifier, IAssetVerifier {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Parses the transaction data to make sure the transaction is valid
    * @param pool Address of the pool
    * @param data Transaction call data
    * @return (bool, address, uint) Whether the transaction is valid, the received asset, and the transaction type.
    */
    function verify(address pool, address, bytes calldata data) external virtual override returns (bool, address, uint) {
        bytes4 method = getMethod(data);

        if (method == bytes4(keccak256("approve(address,uint256)")))
        {
            address spender = convert32toAddress(getInput(data, 0));
            uint amount = uint(getInput(data, 1));

            //Only check for contract verifier, since an asset probably won't call transferFrom() on another asset
            address verifier = ADDRESS_RESOLVER.contractVerifiers(spender);

            //Checks if the spender is an approved address
            require(verifier != address(0), "ERC20Verifier: unsupported spender approval"); 

            emit Approve(pool, spender, amount);

            return (true, address(0), 1);
        }

        return (false, address(0), 0);
    }

    /**
    * @dev Creates transaction data for withdrawing tokens
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @param portion Portion of the pool's balance in the asset
    * @return (WithdrawalData) A struct containing the asset withdrawn, amount of asset withdrawn, and the transactions used to execute the withdrawal.
    */
    function prepareWithdrawal(address pool, address asset, uint portion) external view virtual override returns (WithdrawalData memory) {
        return WithdrawalData({
            withdrawalAsset: asset,
            withdrawalAmount: getBalance(pool, asset).mul(portion).div(10**18),
            externalAddresses: new address[](0),
            transactionDatas: new bytes[](0)
        });
    }

    /**
    * @dev Returns the pool's balance in the asset
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @return uint Pool's balance in the asset
    */
    function getBalance(address pool, address asset) public view virtual override returns (uint) {
        return IERC20(asset).balanceOf(pool);
    }

    /**
    * @dev Returns the decimals of the asset
    * @param asset Address of the asset
    * @return uint Asset's number of decimals
    */
    function getDecimals(address asset) external view override returns (uint) {
        return IERC20(asset).decimals();
    }

    /* ========== EVENTS ========== */

    event Approve(address pool, address spender, uint amount);
}