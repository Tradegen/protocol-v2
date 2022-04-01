// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Libraries
import "../../libraries/TxDataUtils.sol";
import "../../openzeppelin-solidity/contracts/SafeMath.sol";
import "../../openzeppelin-solidity/contracts/Ownable.sol";


//Inheritance
import "./ERC20Verifier.sol";
import "../../interfaces/IUbeswapLPVerifier.sol";

//Internal references
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IAssetHandler.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/Ubeswap/IStakingRewards.sol";

contract UbeswapLPVerifier is ERC20Verifier, Ownable, IUbeswapLPVerifier {
    using SafeMath for uint;

    mapping (address => address) public ubeswapFarms;
    mapping (address => address) public stakingTokens; //farm => pair
    mapping (address => address) public rewardTokens; //farm => reward token

    constructor(address _addressResolver) Ownable() ERC20Verifier(_addressResolver) {}

    /* ========== VIEWS ========== */

    /**
    * @dev Creates transaction data for withdrawing tokens
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @param portion Portion of the pool's balance in the asset
    * @return (WithdrawalData) A struct containing the asset withdrawn, amount of asset withdrawn, and the transactions used to execute the withdrawal.
    */
    function prepareWithdrawal(address pool, address asset, uint portion) external view override returns (WithdrawalData memory) {
        require(pool != address(0), "UbeswapLPVerifier: invalid pool address");
        require(asset != address(0), "UbeswapLPVerifier: invalid asset address");
        require(portion > 0, "UbeswapLPVerifier: portion must be greater than 0");

        uint stakedBalance = IStakingRewards(ubeswapFarms[asset]).balanceOf(pool);

        address[] memory addresses = new address[](stakedBalance > 0 ? 1 : 0);
        bytes[] memory data = new bytes[](stakedBalance > 0 ? 1 : 0);

        //Prepare transaction data
        if (stakedBalance > 0)
        {
            uint stakedWithdrawBalance = stakedBalance.mul(portion).div(10**18);
            addresses[0] = ubeswapFarms[asset];
            data[0] = abi.encodeWithSelector(bytes4(keccak256("withdraw(uint256)")), stakedWithdrawBalance);
        }

        return WithdrawalData({
            withdrawalAsset: asset,
            withdrawalAmount: IERC20(asset).balanceOf(pool).mul(portion).div(10**18),
            externalAddresses: addresses,
            transactionDatas: data
        });
    }

    /**
    * @dev Returns the pool's balance in the asset
    * @notice May included staked balance in external contracts
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @return uint Pool's balance in the asset
    */
    function getBalance(address pool, address asset) public view override returns (uint) {
        require(pool != address(0), "UbeswapLPVerifier: invalid pool address");
        require(asset != address(0), "UbeswapLPVerifier: invalid asset address");

        uint poolBalance = IERC20(asset).balanceOf(pool);
        uint stakedBalance = IStakingRewards(ubeswapFarms[asset]).balanceOf(pool);

        return poolBalance.add(stakedBalance);
    }

    /**
    * @dev Given the address of a farm, returns the farm's staking token and reward token
    * @param farmAddress Address of the farm
    * @return (address, address) Address of the staking token and reward token
    */
    function getFarmTokens(address farmAddress) external view override returns (address, address) {
        require(farmAddress != address(0), "UbeswapLPVerifier: invalid farm address");

        return (stakingTokens[farmAddress], rewardTokens[farmAddress]);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Updates the farm address for the pair
    * @notice Meant to be called by contract owner
    * @param pair Address of pair on Ubeswap
    * @param farmAddress Address of farm on Ubeswap
    * @param rewardToken Address of token paid to stakers
    */
    function setFarmAddress(address pair, address farmAddress, address rewardToken) external onlyOwner {
        require(pair != address(0), "UbeswapLPVerifier: invalid pair address");
        require(farmAddress != address(0), "UbeswapLPVerifier: invalid farm address");
        require(rewardToken != address(0), "UbeswapLPVerifier: invalid reward token");

        ubeswapFarms[pair] = farmAddress;
        stakingTokens[farmAddress] = pair;
        rewardTokens[farmAddress] = rewardToken;

        emit UpdatedFarmAddress(pair, farmAddress, rewardToken);
    }

    /* ========== EVENTS ========== */

    event UpdatedFarmAddress(address pair, address farmAddress, address rewardToken);
}