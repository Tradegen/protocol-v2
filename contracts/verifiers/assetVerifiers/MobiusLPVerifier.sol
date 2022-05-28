// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Libraries.
import "../../openzeppelin-solidity/contracts/SafeMath.sol";
import "../../openzeppelin-solidity/contracts/Ownable.sol";

// Inheritance.
import "./ERC20Verifier.sol";
import "../../interfaces/IMobiusLPVerifier.sol";

// Internal references.
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IAssetHandler.sol";
import "../../interfaces/Mobius/IMasterMind.sol";

contract MobiusLPVerifier is ERC20Verifier, Ownable, IMobiusLPVerifier {
    using SafeMath for uint256;

    IMasterMind public MASTER_MIND;

    // (LP token address => farm ID)
    mapping (address => uint256) public stakingTokens; 

    // (farm ID => LP token address)
    // address(0) if the farm ID not supported
    mapping (uint256 => address) public mobiusFarms; 

    //MOBI token
    address public rewardToken;

    constructor(address _addressResolver, address _mobiusMasterMind, address _rewardToken) Ownable() ERC20Verifier(_addressResolver) {
        MASTER_MIND = IMasterMind(_mobiusMasterMind);
        rewardToken = _rewardToken;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Creates transaction data for withdrawing tokens.
    * @param _pool Address of the pool.
    * @param _asset Address of the asset.
    * @param _portion Portion of the pool's balance in the asset.
    * @return (WithdrawalData) A struct containing the asset withdrawn, amount of asset withdrawn, and the transactions used to execute the withdrawal.
    */
    function prepareWithdrawal(address _pool, address _asset, uint256 _portion) external view override returns (WithdrawalData memory) {
        require(_pool != address(0), "MobiusLPVerifier: Invalid pool address.");
        require(_asset != address(0), "MobiusLPVerifier: Invalid asset address.");
        require(_portion > 0, "MobiusLPVerifier: Portion must be greater than 0.");
        require(mobiusFarms[stakingTokens[_asset]] == _asset, "MobiusLPVerifier: Asset not supported.");

        uint256 stakedBalance = MASTER_MIND.userInfo(stakingTokens[_asset], _pool).amount;

        address[] memory addresses = new address[](stakedBalance > 0 ? 1 : 0);
        bytes[] memory data = new bytes[](stakedBalance > 0 ? 1 : 0);

        // Prepare transaction data.
        if (stakedBalance > 0)
        {
            uint256 stakedWithdrawBalance = stakedBalance.mul(_portion).div(10**18);
            addresses[0] = address(MASTER_MIND);
            data[0] = abi.encodeWithSelector(bytes4(keccak256("withdraw(uint256,uint256)")), stakingTokens[_asset], stakedWithdrawBalance);
        }

        return WithdrawalData({
            withdrawalAsset: _asset,
            withdrawalAmount: IERC20(_asset).balanceOf(_pool).mul(_portion).div(10 ** 18),
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
        require(_pool != address(0), "MobiusLPVerifier: Invalid pool address");
        require(_asset != address(0), "MobiusLPVerifier: Invalid asset address");
        require(mobiusFarms[stakingTokens[_asset]] == _asset, "MobiusLPVerifier: Asset not supported.");

        uint256 poolBalance = IERC20(_asset).balanceOf(_pool);
        uint256 stakedBalance = MASTER_MIND.userInfo(stakingTokens[_asset], _pool).amount;

        return poolBalance.add(stakedBalance);
    }

    /**
    * @notice Given the staking token of a farm, returns the farm's ID and the reward token.
    * @dev Returns address(0) for staking token if the farm ID is not valid.
    * @param _stakingToken Address of the farm's staking token.
    * @return (uint256, address) The staking token's farm ID and the reward token.
    */
    function getFarmID(address _stakingToken) external view override returns (uint256, address) {
        require(_stakingToken != address(0), "MobiusLPVerifier: Invalid staking token address.");
        require(mobiusFarms[stakingTokens[_stakingToken]] == _stakingToken, "MobiusLPVerifier: Asset not supported.");

        return (stakingTokens[_stakingToken], rewardToken);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Updates the farm ID for the LP token.
    * @dev Meant to be called by contract owner.
    * @param _stakingToken Address of the LP token.
    * @param _pid Farm ID for the LP token.
    */
    function setFarmAddress(address _stakingToken, uint256 _pid) external onlyOwner {
        require(_stakingToken != address(0), "MobiusLPVerifier: Invalid staking token address");
        require(_pid >= 0, "MobiusLPVerifier: Invalid pid.");
        require(mobiusFarms[_pid] == address(0), "MobiusLPVerifier: Farm already exists.");

        mobiusFarms[_pid] = _stakingToken;
        stakingTokens[_stakingToken] = _pid;

        emit UpdatedFarmAddress(_stakingToken, _pid);
    }

    /* ========== EVENTS ========== */

    event UpdatedFarmAddress(address stakingToken, uint256 pid);
}