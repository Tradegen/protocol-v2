const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
/*
describe("UbeswapFarmVerifier", () => {
  let deployer;
  let otherUser;

  let bytes;
  let bytesAddress;
  let BytesFactory;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let ubeswapAdapter;
  let ubeswapAdapterAddress;
  let UbeswapAdapterFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let stakingToken;
  let rewardToken;
  let mockStablecoin;
  let stakingTokenAddress;
  let rewardTokenAddress;
  let mockStablecoinAddress;
  let TokenFactory;

  let testPriceCalculator1;
  let testPriceCalculator2;
  let testPriceCalculatorAddress1;
  let testPriceCalculatorAddress2;
  let PriceCalculatorFactory;

  let testStakingRewards;
  let testStakingRewardsAddress;
  let StakingRewardsFactory;

  let ubeswapLPVerifier;
  let ubeswapLPVerifierAddress;
  let UbeswapLPVerifierFactory;

  let ubeswapFarmVerifier;
  let ubeswapFarmVerifierAddress;
  let UbeswapFarmVerifierFactory;
  
  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    BytesFactory = await ethers.getContractFactory('Bytes');
    bytes = await BytesFactory.deploy();
    await bytes.deployed();
    bytesAddress = bytes.address;

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    UbeswapAdapterFactory = await ethers.getContractFactory('UbeswapAdapter');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    PriceCalculatorFactory = await ethers.getContractFactory('TestPriceCalculator');
    StakingRewardsFactory = await ethers.getContractFactory('TestStakingRewards');
    UbeswapLPVerifierFactory = await ethers.getContractFactory('UbeswapLPVerifier', {
      libraries: {
          Bytes: bytesAddress,
      },
    });
    UbeswapFarmVerifierFactory = await ethers.getContractFactory('UbeswapFarmVerifier', {
      libraries: {
          Bytes: bytesAddress,
      },
    });

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    ubeswapAdapter = await UbeswapAdapterFactory.deploy(addressResolverAddress);
    await ubeswapAdapter.deployed();
    ubeswapAdapterAddress = ubeswapAdapter.address;

    testPriceCalculator1 = await PriceCalculatorFactory.deploy();
    await testPriceCalculator1.deployed();
    testPriceCalculatorAddress1 = testPriceCalculator1.address;

    testPriceCalculator2 = await PriceCalculatorFactory.deploy();
    await testPriceCalculator2.deployed();
    testPriceCalculatorAddress2 = testPriceCalculator2.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    ubeswapLPVerifier = await UbeswapLPVerifierFactory.deploy(addressResolverAddress);
    await ubeswapLPVerifier.deployed();
    ubeswapLPVerifierAddress = ubeswapLPVerifier.address;

    stakingToken = await TokenFactory.deploy("Staking Token", "STK");
    await stakingToken.deployed();
    stakingTokenAddress = stakingToken.address;

    rewardToken = await TokenFactory.deploy("Reward Token", "RWD");
    await rewardToken.deployed();
    rewardTokenAddress = rewardToken.address;

    mockStablecoin = await TokenFactory.deploy("Stablecoin", "SGD");
    await mockStablecoin.deployed();
    mockStablecoinAddress = mockStablecoin.address;

    testStakingRewards = await StakingRewardsFactory.deploy();
    await testStakingRewards.deployed();
    testStakingRewardsAddress = testStakingRewards.address;

    await addressResolver.setContractAddress("UbeswapAdapter", ubeswapAdapterAddress);
    await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await addressResolver.setAssetVerifier(2, ubeswapLPVerifierAddress);

    await assetHandler.addAssetType(1, testPriceCalculatorAddress1);
    await assetHandler.addAssetType(2, testPriceCalculatorAddress2);
    await assetHandler.addCurrencyKey(1, rewardTokenAddress);
    await assetHandler.addCurrencyKey(2, stakingTokenAddress);
    await assetHandler.setStableCoinAddress(mockStablecoinAddress);

    let tx = await ubeswapLPVerifier.setFarmAddress(stakingTokenAddress, testStakingRewardsAddress, rewardTokenAddress);
    await tx.wait();
  });

  beforeEach(async () => {
    ubeswapFarmVerifier = await UbeswapFarmVerifierFactory.deploy(addressResolverAddress);
    await ubeswapFarmVerifier.deployed();
    ubeswapFarmVerifierAddress = ubeswapFarmVerifier.address;
  });
  
  describe("#verify stake()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'stake',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = await ubeswapFarmVerifier.verify(deployer.address, testStakingRewardsAddress, params);
      expect(tx).to.emit(ubeswapFarmVerifier, "Staked");
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'stake',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'amount'
            }]
        }, [mockStablecoinAddress]);
  
      let tx = ubeswapFarmVerifier.verify(deployer.address, testStakingRewardsAddress, params);
      expect(tx).to.not.emit(ubeswapFarmVerifier, "Staked");
    });

    it('correct format but unsupported sender', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'stake',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = ubeswapFarmVerifier.verify(deployer.address, otherUser.address, params);
      expect(tx).to.not.emit(ubeswapFarmVerifier, "Staked");
    });
  });
  
  describe("#verify withdraw()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = await ubeswapFarmVerifier.verify(deployer.address, testStakingRewardsAddress, params);
      expect(tx).to.emit(ubeswapFarmVerifier, "Unstaked");
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'amount'
            }]
        }, [mockStablecoinAddress]);
  
      let tx = ubeswapFarmVerifier.verify(deployer.address, testStakingRewardsAddress, params);
      expect(tx).to.not.emit(ubeswapFarmVerifier, "Staked");
    });

    it('correct format but unsupported sender', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = ubeswapFarmVerifier.verify(deployer.address, otherUser.address, params);
      expect(tx).to.not.emit(ubeswapFarmVerifier, "Unstaked");
    });
  });
  
  describe("#verify getReward()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'getReward',
            type: 'function',
            inputs: []
        }, []);
  
      let tx = await ubeswapFarmVerifier.verify(deployer.address, testStakingRewardsAddress, params);
      expect(tx).to.emit(ubeswapFarmVerifier, "ClaimedReward");
    });

    it('getReward() wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'getReward',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = ubeswapFarmVerifier.verify(deployer.address, testStakingRewardsAddress, params);
      expect(tx).to.not.emit(ubeswapFarmVerifier, "ClaimedReward");
    });

    it('correct format but unsupported sender', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'getReward',
            type: 'function',
            inputs: []
        }, []);
  
      let tx = ubeswapFarmVerifier.verify(deployer.address, otherUser.address, params);
      await expect(tx).to.be.reverted;
    });
  });
  
  describe("#verify exit()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'exit',
            type: 'function',
            inputs: []
        }, []);
  
      let tx = await ubeswapFarmVerifier.verify(deployer.address, testStakingRewardsAddress, params);
      expect(tx).to.emit(ubeswapFarmVerifier, "Unstaked");
      expect(tx).to.emit(ubeswapFarmVerifier, "ClaimedReward");
    });

    it('exit() wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'exit',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = ubeswapFarmVerifier.verify(deployer.address, testStakingRewardsAddress, params);
      expect(tx).to.not.emit(ubeswapFarmVerifier, "Unstaked");
      expect(tx).to.not.emit(ubeswapFarmVerifier, "ClaimedReward");
    });

    it('correct format but unsupported sender', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'exit',
            type: 'function',
            inputs: []
        }, []);
  
      let tx = ubeswapFarmVerifier.verify(deployer.address, otherUser.address, params);
      await expect(tx).to.be.reverted;
    });
  });
});*/