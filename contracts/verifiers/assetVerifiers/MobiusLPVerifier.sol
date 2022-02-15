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

    IAddressResolver public ADDRESS_RESOLVER;
    IMasterMind public MASTER_MIND;

    mapping (address => uint) public stakingTokens; //LP token address => farm ID
    mapping (uint => address) public mobiusFarms; //farm ID => LP token address (address(0) if farm ID not supported)
    address public rewardToken; //MOBI token

    constructor(address _addressResolver, address _mobiusMasterMind, address _rewardToken) Ownable() {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
        MASTER_MIND = IMasterMind(_mobiusMasterMind);
        rewardToken = _rewardToken;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Creates transaction data for withdrawing tokens
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @param portion Portion of the pool's balance in the asset
    * @return (address, uint, MultiTransaction[]) Withdrawn asset, amount of asset withdrawn, and transactions used to execute the withdrawal
    */
    function prepareWithdrawal(address pool, address asset, uint portion) external view override returns (address, uint, MultiTransaction[] memory transactions) {
        require(pool != address(0), "MobiusLPVerifier: invalid pool address");
        require(asset != address(0), "MobiusLPVerifier: invalid asset address");
        require(portion > 0, "MobiusLPVerifier: portion must be greater than 0");
        require(mobiusFarms[stakingTokens[asset]] == asset, "MobiusLPVerifier: asset not supported.");

        uint poolBalance = IERC20(asset).balanceOf(pool);
        uint withdrawBalance = poolBalance.mul(portion).div(10**18);
        uint stakedBalance = MASTER_MIND.userInfo(stakingTokens[asset], pool).amount;

        //Prepare transaction data
        if (stakedBalance > 0)
        {
            uint stakedWithdrawBalance = stakedBalance.mul(portion).div(10**18);
            transactions = new MultiTransaction[](1);
            transactions[0].to = address(MASTER_MIND);
            transactions[0].txData = abi.encodeWithSelector(bytes4(keccak256("withdraw(uint256,uint256)")), stakedWithdrawBalance);
        }

        return (asset, withdrawBalance, transactions);
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