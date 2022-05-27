// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Libraries.
import "../../libraries/Bytes.sol";
import "../../openzeppelin-solidity/contracts/SafeMath.sol";
import "../../openzeppelin-solidity/contracts/Ownable.sol";


// Inheritance.
import "./ERC20Verifier.sol";
import "../../interfaces/IUbeswapLPVerifier.sol";

// Internal references.
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IAssetHandler.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/Ubeswap/IStakingRewards.sol";

contract UbeswapLPVerifier is ERC20Verifier, Ownable, IUbeswapLPVerifier {
    using SafeMath for uint256;

    // (LP token address => Ubeswap farm address).
    mapping (address => address) public ubeswapFarms;

    // (Ubeswap farm address => LP token address).
    mapping (address => address) public stakingTokens;

    // (Ubeswap farm address => reward token address).
    mapping (address => address) public rewardTokens;

    constructor(address _addressResolver) Ownable() ERC20Verifier(_addressResolver) {}

    /* ========== VIEWS ========== */

    /**
    * @notice Creates transaction data for withdrawing tokens.
    * @param _pool Address of the pool.
    * @param _asset Address of the asset.
    * @param _portion Portion of the pool's balance in the asset.
    * @return (WithdrawalData) A struct containing the asset withdrawn, amount of asset withdrawn, and the transactions used to execute the withdrawal.
    */
    function prepareWithdrawal(address _pool, address _asset, uint256 _portion) external view override returns (WithdrawalData memory) {
        require(_pool != address(0), "UbeswapLPVerifier: Invalid pool address.");
        require(_asset != address(0), "UbeswapLPVerifier: Invalid asset address.");
        require(_portion > 0, "UbeswapLPVerifier: Portion must be greater than 0.");

        uint256 stakedBalance = IStakingRewards(ubeswapFarms[_asset]).balanceOf(_pool);

        address[] memory addresses = new address[](stakedBalance > 0 ? 1 : 0);
        bytes[] memory data = new bytes[](stakedBalance > 0 ? 1 : 0);

        // Prepare transaction data.
        if (stakedBalance > 0)
        {
            uint256 stakedWithdrawBalance = stakedBalance.mul(_portion).div(10**18);
            addresses[0] = ubeswapFarms[_asset];
            data[0] = abi.encodeWithSelector(bytes4(keccak256("withdraw(uint256)")), stakedWithdrawBalance);
        }

        return WithdrawalData({
            withdrawalAsset: _asset,
            withdrawalAmount: IERC20(_asset).balanceOf(_pool).mul(_portion).div(10**18),
            externalAddresses: addresses,
            transactionDatas: data
        });
    }

    /**
    * @notice Returns the pool's balance in the asset.
    * @dev May include staked balance in external contracts.
    * @param _pool Address of the pool.
    * @param _asset Address of the asset.
    * @return uint256 Pool's balance in the asset.
    */
    function getBalance(address _pool, address _asset) public view override returns (uint256) {
        require(_pool != address(0), "UbeswapLPVerifier: Invalid pool address.");
        require(_asset != address(0), "UbeswapLPVerifier: Invalid asset address.");

        uint256 poolBalance = IERC20(_asset).balanceOf(_pool);
        uint256 stakedBalance = IStakingRewards(ubeswapFarms[_asset]).balanceOf(_pool);

        return poolBalance.add(stakedBalance);
    }

    /**
    * @notice Given the address of a farm, returns the farm's staking token and reward token.
    * @param _farmAddress Address of the farm.
    * @return (address, address) Address of the staking token and reward token.
    */
    function getFarmTokens(address _farmAddress) external view override returns (address, address) {
        require(_farmAddress != address(0), "UbeswapLPVerifier: Invalid farm address.");

        return (stakingTokens[_farmAddress], rewardTokens[_farmAddress]);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Updates the farm address for the pair.
    * @notice Meant to be called by contract owner.
    * @param _pair Address of pair on Ubeswap.
    * @param _farmAddress Address of farm on Ubeswap.
    * @param _rewardToken Address of token paid to stakers.
    */
    function setFarmAddress(address _pair, address _farmAddress, address _rewardToken) external onlyOwner {
        require(_pair != address(0), "UbeswapLPVerifier: Invalid pair address.");
        require(_farmAddress != address(0), "UbeswapLPVerifier: Invalid farm address.");
        require(_rewardToken != address(0), "UbeswapLPVerifier: Invalid reward token.");

        ubeswapFarms[_pair] = _farmAddress;
        stakingTokens[_farmAddress] = _pair;
        rewardTokens[_farmAddress] = _rewardToken;

        emit UpdatedFarmAddress(_pair, _farmAddress, _rewardToken);
    }

    /* ========== EVENTS ========== */

    event UpdatedFarmAddress(address pair, address farmAddress, address rewardToken);
}