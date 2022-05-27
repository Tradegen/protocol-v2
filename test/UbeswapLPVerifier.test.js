const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("UbeswapLPVerifier", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let stakingToken;
  let rewardToken;
  let stakingTokenAddress;
  let rewardTokenAddress;
  let TokenFactory;

  let ubeswapLPVerifier;
  let ubeswapLPVerifierAddress;
  let UbeswapLPVerifierFactory;

  let testStakingRewards;
  let testStakingRewardsAddress;
  let StakingRewardsFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    UbeswapLPVerifierFactory = await ethers.getContractFactory('UbeswapLPVerifier');
    StakingRewardsFactory = await ethers.getContractFactory('TestStakingRewards');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    stakingToken = await TokenFactory.deploy("Staking Token", "STK");
    await stakingToken.deployed();
    stakingTokenAddress = stakingToken.address;

    rewardToken = await TokenFactory.deploy("Reward Token", "RWD");
    await rewardToken.deployed();
    rewardTokenAddress = rewardToken.address;

    testStakingRewards = await StakingRewardsFactory.deploy();
    await testStakingRewards.deployed();
    testStakingRewardsAddress = testStakingRewards.address;
  });

  beforeEach(async () => {
    ubeswapLPVerifier = await UbeswapLPVerifierFactory.deploy(addressResolverAddress);
    await ubeswapLPVerifier.deployed();
    ubeswapLPVerifierAddress = ubeswapLPVerifier.address;

    let tx = await ubeswapLPVerifier.setFarmAddress(stakingTokenAddress, testStakingRewardsAddress, rewardTokenAddress);
    await tx.wait();
  });
  
  describe("#getFarm", () => {
    it("get Ubeswap farm", async () => {
      const farm = await ubeswapLPVerifier.ubeswapFarms(stakingTokenAddress);
      expect(farm).to.equal(testUbeswapFarmAddress);
    });
  });
  
  describe("#getBalance", () => {
    it("get balance", async () => {
      let tx = await testStakingRewards.setBalance(deployer.address, parseEther("1"));
      await tx.wait();

      const value = await ubeswapLPVerifier.getBalance(deployer.address, stakingTokenAddress);
      expect(value).to.equal(parseEther("1"));
    });
  });
  
  describe("#prepareWithdrawal", () => {
    it("prepare withdrawal", async () => {
      let tx = await testStakingRewards.setBalance(deployer.address, parseEther("1"));
      await tx.wait();

      const data = await ubeswapLPVerifier.prepareWithdrawal(deployer.address, stakingTokenAddress, 10000);
      
      expect(data[0]).to.equal(stakingTokenAddress);
      expect(data[1]).to.equal(10000);
      expect(data[2].length).to.equal(1);
      expect(data[3].length).to.equal(1);
    });
  });

  describe("#getFarmTokens", () => {
    it("get farm tokens", async () => {
      const data = await ubeswapLPVerifier.getFarmTokens(testStakingRewardsAddress);
      
      expect(data.length).to.equal(2);
      expect(data[0]).to.equal(stakingTokenAddress);
      expect(data[1]).to.equal(rewardTokenAddress);
    });
  });
});