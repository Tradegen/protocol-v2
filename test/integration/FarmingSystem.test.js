const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const Web3 = require("web3");
const { ethers } = require("hardhat");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');

describe("CappedPool", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let cappedPool;
  let cappedPoolAddress;
  let CappedPoolFactory;

  let poolManagerLogic;
  let poolManagerLogicAddress;
  let PoolManagerLogicFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let settings;
  let settingsAddress;
  let SettingsFactory;

  let stablecoin;
  let tradegenToken;
  let stablecoinAddress;
  let tradegenTokenAddress;
  let TokenFactory;

  let bytes;
  let bytesAddress;
  let BytesFactory;

  let ERC20Verifier;
  let ERC20VerifierAddress;
  let ERC20VerifierFactory;

  let cappedPoolNFT;
  let cappedPoolNFTAddress;
  let CappedPoolNFTFactory;

  // Farming system.

  let poolManager;
  let poolManagerAddress;
  let PoolManagerFactory;

  let releaseSchedule;
  let releaseScheduleAddress;
  let ReleaseScheduleFactory;

  let releaseEscrow;
  let releaseEscrowAddress;
  let ReleaseEscrowFactory;

  let stakingRewardsFactoryContract;
  let stakingRewardsFactoryAddress;
  let StakingRewardsFactoryFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    BytesFactory = await ethers.getContractFactory('Bytes');
    bytes = await BytesFactory.deploy();
    await bytes.deployed();
    bytesAddress = bytes.address;

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    PoolManagerLogicFactory = await ethers.getContractFactory('PoolManagerLogic');
    SettingsFactory = await ethers.getContractFactory('Settings');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    CappedPoolFactory = await ethers.getContractFactory('CappedPool');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    PoolManagerFactory = await ethers.getContractFactory('TestPoolManager2');
    CappedPoolNFTFactory = await ethers.getContractFactory('CappedPoolNFT');
    StakingRewardsFactoryFactory = await ethers.getContractFactory('StakingRewardsFactory');
    ReleaseScheduleFactory = await ethers.getContractFactory('HalveningReleaseSchedule');
    ReleaseEscrowFactory = await ethers.getContractFactory('ReleaseEscrow');
    ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier', {
        libraries: {
            Bytes: bytesAddress,
        },
      });

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    settings = await SettingsFactory.deploy();
    await settings.deployed();
    settingsAddress = settings.address;

    stablecoin = await TokenFactory.deploy("Stablecoin", "SGD");
    await stablecoin.deployed();
    stablecoinAddress = stablecoin.address;

    tradegenToken = await TokenFactory.deploy("Tradegen", "TGEN");
    await tradegenToken.deployed();
    tradegenTokenAddress = tradegenToken.address;

    poolManagerLogic = await PoolManagerLogicFactory.deploy(deployer.address, 1000, addressResolverAddress);
    await poolManagerLogic.deployed();
    poolManagerLogicAddress = poolManagerLogic.address;

    ERC20Verifier = await ERC20VerifierFactory.deploy(addressResolverAddress);
    await ERC20Verifier.deployed();
    ERC20VerifierAddress = ERC20Verifier.address;

    // Farming system.

    let currentTime = await assetHandler.getCurrentTime();

    releaseSchedule = await ReleaseScheduleFactory.deploy(parseEther("100"), Number(currentTime) + 6);
    await releaseSchedule.deployed();
    releaseScheduleAddress = releaseSchedule.address;

    stakingRewardsFactoryContract = await StakingRewardsFactoryFactory.deploy(tradegenTokenAddress, addressResolverAddress);
    await stakingRewardsFactoryContract.deployed();
    stakingRewardsFactoryAddress = stakingRewardsFactoryContract.address;

    poolManager = await PoolManagerFactory.deploy(tradegenTokenAddress, releaseScheduleAddress, deployer.address, stakingRewardsFactoryAddress, tradegenTokenAddress, addressResolverAddress);
    await poolManager.deployed();
    poolManagerAddress = poolManager.address;

    let tx = await stakingRewardsFactoryContract.setPoolManager(poolManagerAddress);
    await tx.wait();

    releaseEscrow = await ReleaseEscrowFactory.deploy(poolManagerAddress, tradegenTokenAddress, releaseScheduleAddress, Number(currentTime) + 6);
    await releaseEscrow.deployed();
    releaseEscrowAddress = releaseEscrow.address;

    let txx = await poolManager.setReleaseEscrow(releaseEscrowAddress);
    await txx.wait();

    let txxx = await tradegenToken.transfer(releaseEscrowAddress, parseEther("200"));
    await txxx.wait();

    // Initialize contracts.

    let tx1 = await addressResolver.setContractAddress("Settings", settingsAddress);
    await tx1.wait();

    let tx2 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("Registry", deployer.address);
    await tx3.wait();

    let tx4 = await assetHandler.setStableCoinAddress(stablecoinAddress);
    await tx4.wait();

    let tx5 = await settings.setParameterValue("MaximumNumberOfPositionsInPool", 3);
    await tx5.wait();

    let tx6 = await assetHandler.setValidAsset(stablecoinAddress, 1);
    await tx6.wait();

    let tx7 = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
    await tx7.wait();

    let tx8 = await poolManagerLogic.addAvailableAsset(stablecoinAddress);
    await tx8.wait();

    let tx9 = await poolManagerLogic.addDepositAsset(stablecoinAddress);
    await tx9.wait();

    let tx10 = await poolManagerLogic.addAvailableAsset(tradegenTokenAddress);
    await tx10.wait();

    let tx11 = await poolManagerLogic.addDepositAsset(tradegenTokenAddress);
    await tx11.wait();

    let tx12 = await stablecoin.transfer(otherUser.address, parseEther("10000"));
    await tx12.wait();

    let tx13 = await tradegenToken.transfer(otherUser.address, parseEther("10000"));
    await tx13.wait();

    let tx14 = await assetHandler.setVerifier(stablecoinAddress, ERC20VerifierAddress);
    await tx14.wait();

    let tx15 = await assetHandler.setVerifier(tradegenTokenAddress, ERC20VerifierAddress);
    await tx15.wait();

    let tx16 = await addressResolver.setContractAddress("PoolManager", poolManagerAddress);
    await tx16.wait();

    let tx17 = await settings.setParameterValue("TimeBetweenFeeSnapshots", 1000);
    await tx17.wait();
  });

  beforeEach(async () => {
    cappedPool = await CappedPoolFactory.deploy("Pool", parseEther("1"), 1000, deployer.address, addressResolverAddress, poolManagerAddress);
    await cappedPool.deployed();
    cappedPoolAddress = cappedPool.address;

    cappedPoolNFT = await CappedPoolNFTFactory.deploy(cappedPoolAddress, 1000);
    await cappedPoolNFT.deployed();
    cappedPoolNFTAddress = cappedPoolNFT.address;

    let tx = await cappedPool.initializeContracts(cappedPoolNFTAddress, poolManagerLogicAddress);
    await tx.wait();
  });
  
  describe("#deposit", () => {
    it("meets requirements", async () => {
        let tx = await assetHandler.setBalance(stablecoinAddress, parseEther("100"));
        await tx.wait();

        let tx2 = await stablecoin.approve(cappedPoolAddress, parseEther("100"));
        await tx2.wait();

        let tx3 = await cappedPool.deposit(100, stablecoinAddress);
        await tx3.wait();

        let balanceOf1 = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf1).to.equal(50);

        let balanceOf2 = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOf2).to.equal(50);

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(100);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(100);

        let userDeposits = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDeposits).to.equal(parseEther("100"));

        let totalDeposits = await cappedPoolNFT.totalDeposits();
        expect(totalDeposits).to.equal(parseEther("100"));

        let poolValue = await cappedPool.getPoolValue();
        expect(poolValue).to.equal(parseEther("100"));

        let tokenPrice = await cappedPool.tokenPrice();
        expect(tokenPrice).to.equal(parseEther("1"));

        let availableTokensPerClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensPerClass[0]).to.equal(0);
        expect(availableTokensPerClass[1]).to.equal(50);
        expect(availableTokensPerClass[2]).to.equal(200);
        expect(availableTokensPerClass[3]).to.equal(650);

        let tokenBalancePerClass = await cappedPoolNFT.getTokenBalancePerClass(deployer.address);
        expect(tokenBalancePerClass[0]).to.equal(50);
        expect(tokenBalancePerClass[1]).to.equal(50);
        expect(tokenBalancePerClass[2]).to.equal(0);
        expect(tokenBalancePerClass[3]).to.equal(0);

        let poolBalance = await stablecoin.balanceOf(cappedPoolAddress);
        expect(poolBalance).to.equal(parseEther("100"));
    });
  });
  
  describe("#withdraw", () => {
    it("meets requirements; partial", async () => {
        let tx = await stablecoin.approve(cappedPoolAddress, parseEther("100"));
        await tx.wait();

        let tx2 = await cappedPool.deposit(100, stablecoinAddress);
        await tx2.wait();

        let tx3 = await assetHandler.setBalance(stablecoinAddress, parseEther("100"));
        await tx3.wait();

        let initialBalanceStablecoinDeployer = await stablecoin.balanceOf(deployer.address);
        let initialBalanceStablecoinPool = await stablecoin.balanceOf(cappedPoolAddress);

        let tx4 = await cappedPool.withdraw(50, 1);
        await tx4.wait();

        let tx5 = await assetHandler.setBalance(stablecoinAddress, parseEther("50"));
        await tx5.wait();

        let newBalanceStablecoinDeployer = await stablecoin.balanceOf(deployer.address);
        let newBalanceStablecoinPool = await stablecoin.balanceOf(cappedPoolAddress);
        let expectedNewBalanceStablecoinDeployer = BigInt(initialBalanceStablecoinDeployer) + BigInt(parseEther("50"));
        let expectedNewBalanceStablecoinPool = BigInt(initialBalanceStablecoinPool) - BigInt(parseEther("50"));
        expect(newBalanceStablecoinDeployer.toString()).to.equal(expectedNewBalanceStablecoinDeployer.toString());
        expect(newBalanceStablecoinPool.toString()).to.equal(expectedNewBalanceStablecoinPool.toString());

        let balanceOf1 = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf1).to.equal(0);

        let balanceOf2 = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOf2).to.equal(50);

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(50);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(50);

        let userDeposits = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDeposits).to.equal(parseEther("50"));

        let totalDeposits = await cappedPoolNFT.totalDeposits();
        expect(totalDeposits).to.equal(parseEther("50"));

        let poolValue = await cappedPool.getPoolValue();
        expect(poolValue).to.equal(parseEther("50"));

        let tokenPrice = await cappedPool.tokenPrice();
        expect(tokenPrice).to.equal(parseEther("1"));

        let availableTokensPerClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensPerClass[0]).to.equal(50);
        expect(availableTokensPerClass[1]).to.equal(50);
        expect(availableTokensPerClass[2]).to.equal(200);
        expect(availableTokensPerClass[3]).to.equal(650);

        let tokenBalancePerClass = await cappedPoolNFT.getTokenBalancePerClass(deployer.address);
        expect(tokenBalancePerClass[0]).to.equal(0);
        expect(tokenBalancePerClass[1]).to.equal(50);
        expect(tokenBalancePerClass[2]).to.equal(0);
        expect(tokenBalancePerClass[3]).to.equal(0);
    });
  });

  describe("#executeTransaction", () => {
    it("meets requirements", async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'approve',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'spender'
            },{
                type: 'uint256',
                name: 'value'
            }]
          }, [deployer.address, '1000']);

        let tx = await addressResolver.setContractVerifier(deployer.address, deployer.address);
        await tx.wait();

        let tx2 = await cappedPool.executeTransaction(stablecoinAddress, params);
        await tx2.wait();

        let allowance = await stablecoin.allowance(cappedPoolAddress, deployer.address);
        expect(allowance).to.equal(1000);
    });
  });

  describe("#takeSnapshot", () => {
    it("meets requirements", async () => {
        let tx = await assetHandler.setBalance(stablecoinAddress, parseEther("100"));
        await tx.wait();

        let tx2 = await cappedPool.takeSnapshot();
        await tx2.wait();

        let timestampAtLastSnapshot = await cappedPool.timestampAtLastSnapshot();
        expect(Number(timestampAtLastSnapshot)).to.be.greaterThan(0);

        let unrealizedProfitsAtLastSnapshot = await cappedPool.unrealizedProfitsAtLastSnapshot();
        expect(unrealizedProfitsAtLastSnapshot).to.equal(parseEther("100"));
    }); 
  });
});