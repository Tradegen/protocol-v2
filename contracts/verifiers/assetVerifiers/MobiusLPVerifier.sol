// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Libraries
import "../../libraries/TxDataUtils.sol";
import "../../openzeppelin-solidity/contracts/SafeMath.sol";
import "../../openzeppelin-solidity/contracts/Ownable.sol";

//Inheritance
import "./ERC20Verifier.sol";
import "../../interfaces/IMobiusLPVerifier.sol";

//Internal references
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IAssetHandler.sol";
import "../../interfaces/Mobius/IMasterMind.sol";

contract MobiusLPVerifier is ERC20Verifier, Ownable, IMobiusLPVerifier {
    using SafeMath for uint;

    IMasterMind public MASTER_MIND;

    mapping (address => uint) public stakingTokens; //LP token address => farm ID
    mapping (uint => address) public mobiusFarms; //farm ID => LP token address (address(0) if farm ID not supported)
    address public rewardToken; //MOBI token

    constructor(address _addressResolver, address _mobiusMasterMind, address _rewardToken) Ownable() ERC20Verifier(_addressResolver) {
        MASTER_MIND = IMasterMind(_mobiusMasterMind);
        rewardToken = _rewardToken;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Creates transaction data for withdrawing tokens
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @param portion Portion of the pool's balance in the asset
    * @return (WithdrawalData) A struct containing the asset withdrawn, amount of asset withdrawn, and the transactions used to execute the withdrawal.
    */
    function prepareWithdrawal(address pool, address asset, uint portion) external view override returns (WithdrawalData memory) {
        require(pool != address(0), "MobiusLPVerifier: invalid pool address");
        require(asset != address(0), "MobiusLPVerifier: invalid asset address");
        require(portion > 0, "MobiusLPVerifier: portion must be greater than 0");
        require(mobiusFarms[stakingTokens[asset]] == asset, "MobiusLPVerifier: asset not supported.");

        uint stakedBalance = MASTER_MIND.userInfo(stakingTokens[asset], pool).amount;

        address[] memory addresses = new address[](stakedBalance > 0 ? 1 : 0);
        bytes[] memory data = new bytes[](stakedBalance > 0 ? 1 : 0);

        //Prepare transaction data
        if (stakedBalance > 0)
        {
            uint stakedWithdrawBalance = stakedBalance.mul(portion).div(10**18);
            addresses[0] = address(MASTER_MIND);
            data[0] = abi.encodeWithSelector(bytes4(keccak256("withdraw(uint256,uint256)")), stakingTokens[asset], stakedWithdrawBalance);
        }

        return WithdrawalData({
            withdrawalAsset: asset,
            withdrawalAmount: IERC20(asset).balanceOf(pool).mul(portion).div(10 ** 18),
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
        require(pool != address(0), "MobiusLPVerifier: invalid pool address");
        require(asset != address(0), "MobiusLPVerifier: invalid asset address");
        require(mobiusFarms[stakingTokens[asset]] == asset, "MobiusLPVerifier: asset not supported.");

        uint poolBalance = IERC20(asset).balanceOf(pool);
        uint stakedBalance = MASTER_MIND.userInfo(stakingTokens[asset], pool).amount;

        return poolBalance.add(stakedBalance);
    }

    /**
    * @dev Given the staking token of a farm, returns the farm's ID and the reward token.
    * @notice Returns address(0) for staking token if the farm ID is not valid.
    * @param _stakingToken Address of the farm's staking token.
    * @return (address, address) Address of the staking token and reward token.
    */
    function getFarmID(address _stakingToken) external view override returns (uint, address) {
        require(_stakingToken != address(0), "MobiusLPVerifier: invalid staking token address.");
        require(mobiusFarms[stakingTokens[_stakingToken]] == _stakingToken, "MobiusLPVerifier: asset not supported.");

        return (stakingTokens[_stakingToken], rewardToken);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Updates the farm ID for the LP token
    * @notice Meant to be called by contract owner
    * @param _stakingToken Address of the LP token
    * @param _pid Farm ID for the LP token
    */
    function setFarmAddress(address _stakingToken, uint _pid) external onlyOwner {
        require(_stakingToken != address(0), "MobiusLPVerifier: invalid staking token address");
        require(_pid >= 0, "MobiusLPVerifier: invalid pid.");
        require(mobiusFarms[_pid] == address(0), "MobiusLPVerifier: farm already exists.");

        mobiusFarms[_pid] = _stakingToken;
        stakingTokens[_stakingToken] = _pid;

        emit UpdatedFarmAddress(_stakingToken, _pid);
    }

    /* ========== EVENTS ========== */

    event UpdatedFarmAddress(address stakingToken, uint pid);
}