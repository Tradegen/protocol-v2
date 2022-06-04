const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("Registry", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let cappedPoolNFT;
  let cappedPoolNFTAddress;
  let CappedPoolNFTFactory;

  let cappedPool;
  let cappedPoolAddress;
  let CappedPoolFactory;

  let pool;
  let poolAddress;
  let PoolFactory;

  let poolManagerLogic;
  let poolManagerLogicAddress;
  let PoolManagerLogicFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let settings;
  let settingsAddress;
  let SettingsFactory;

  let poolManager;
  let poolManagerAddress;
  let PoolManagerFactory;

  let cappedPoolFactoryContract;
  let cappedPoolFactoryAddress;
  let CappedPoolFactoryFactory;

  let cappedPoolNFTFactoryContract;
  let cappedPoolNFTFactoryAddress;
  let CappedPoolNFTFactoryFactory;

  let poolManagerLogicFactoryContract;
  let poolManagerLogicFactoryAddress;
  let PoolManagerLogicFactoryFactory;

  let poolFactoryContract;
  let poolFactoryAddress;
  let PoolFactoryFactory;

  let registry;
  let registryAddress;
  let RegistryFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    CappedPoolNFTFactory = await ethers.getContractFactory('CappedPoolNFT');
    PoolManagerLogicFactory = await ethers.getContractFactory('PoolManagerLogic');
    SettingsFactory = await ethers.getContractFactory('Settings');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    CappedPoolFactory = await ethers.getContractFactory('CappedPool');
    PoolFactory = await ethers.getContractFactory('Pool');
    PoolFactoryFactory = await ethers.getContractFactory('PoolFactory');
    CappedPoolFactoryFactory = await ethers.getContractFactory('CappedPoolFactory');
    CappedPoolNFTFactoryFactory = await ethers.getContractFactory('CappedPoolNFTFactory');
    PoolManagerLogicFactoryFactory = await ethers.getContractFactory('PoolManagerLogicFactory');
    PoolManagerFactory = await ethers.getContractFactory('TestPoolManager');
    RegistryFactory = await ethers.getContractFactory('Registry');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    settings = await SettingsFactory.deploy();
    await settings.deployed();
    settingsAddress = settings.address;

    poolManager = await PoolManagerFactory.deploy();
    await poolManager.deployed();
    poolManagerAddress = poolManager.address;

    cappedPoolFactoryContract = await CappedPoolFactoryFactory.deploy(addressResolverAddress);
    await cappedPoolFactoryContract.deployed();
    cappedPoolFactoryAddress = cappedPoolFactoryContract.address;

    poolFactoryContract = await PoolFactoryFactory.deploy(addressResolverAddress);
    await poolFactoryContract.deployed();
    poolFactoryAddress = poolFactoryContract.address;

    poolManagerLogicFactoryContract = await PoolManagerLogicFactoryFactory.deploy(addressResolverAddress);
    await poolManagerLogicFactoryContract.deployed();
    poolManagerLogicFactoryAddress = poolManagerLogicFactoryContract.address;

    cappedPoolNFTFactoryContract = await CappedPoolNFTFactoryFactory.deploy(addressResolverAddress);
    await cappedPoolNFTFactoryContract.deployed();
    cappedPoolNFTFactoryAddress = cappedPoolNFTFactoryContract.address;

    let tx = await addressResolver.setContractAddress("Settings", settingsAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("PoolFactory", poolFactoryAddress);
    await tx3.wait();

    let tx4 = await addressResolver.setContractAddress("CappedPoolFactory", cappedPoolFactoryAddress);
    await tx4.wait();

    let tx5 = await addressResolver.setContractAddress("CappedPoolNFTFactory", cappedPoolNFTFactoryAddress);
    await tx5.wait();

    let tx6 = await addressResolver.setContractAddress("PoolManagerLogicFactory", poolManagerLogicFactoryAddress);
    await tx6.wait();

    let tx7 = await addressResolver.setContractAddress("PoolManager", poolManagerAddress);
    await tx7.wait();

    let tx8 = await settings.setParameterValue("MaximumNumberOfPoolsPerUser", 2);
    await tx8.wait();

    let tx9 = await settings.setParameterValue("MaximumPerformanceFee", 10000);
    await tx9.wait();

    let tx10 = await settings.setParameterValue("MaximumNumberOfCappedPoolTokens", 1000000);
    await tx10.wait();

    let tx11 = await settings.setParameterValue("MinimumNumberOfCappedPoolTokens", 100);
    await tx11.wait();

    let tx12 = await settings.setParameterValue("MinimumCappedPoolSeedPrice", parseEther("0.1"));
    await tx12.wait();

    let tx13 = await settings.setParameterValue("MaximumCappedPoolSeedPrice", parseEther("1000"));
    await tx13.wait();
  });

  beforeEach(async () => {
    registry = await RegistryFactory.deploy(addressResolverAddress);
    await registry.deployed();
    registryAddress = registry.address;

    let tx = await addressResolver.setContractAddress("Registry", registryAddress);
    await tx.wait();
  });
  
  describe("#createPool", () => {
    it("pool name too long", async () => {
      let tx = registry.createPool("Pool name that is too long because it contains more than 50 characters, causing the transaction to revert.", 1000);
      await expect(tx).to.be.reverted;

      let userPools = await registry.userPools(deployer.address);
      expect(userPools).to.equal(0);
    });

    it("performance fee too high", async () => {
        let tx = registry.createPool("Pool", 1000000);
        await expect(tx).to.be.reverted;
  
        let userPools = await registry.userPools(deployer.address);
        expect(userPools).to.equal(0);
    });  

    it('meets requirements', async () => {
        let tx = await registry.createPool("Pool", 1000);
        let temp = await tx.wait();
        let event = temp.events[temp.events.length - 1];
        poolAddress = event.args.poolAddress;
        poolManagerLogicAddress = event.args.poolManagerLogicAddress;
        pool = PoolFactory.attach(poolAddress);
        poolManagerLogic = PoolManagerLogicFactory.attach(poolManagerLogicAddress);

        let userPools = await registry.userPools(deployer.address);
        expect(userPools).to.equal(1);

        let name = await pool.name();
        expect(name).to.equal("Pool");

        let manager = await pool.manager();
        expect(manager).to.equal(deployer.address);

        let assignedPoolManagerLogicAddress = await poolManagerLogicFactoryContract.poolManagerLogics(poolAddress);
        expect(assignedPoolManagerLogicAddress).to.equal(poolManagerLogicAddress);

        let poolManagerLogicManager = await poolManagerLogic.manager();
        expect(poolManagerLogicManager).to.equal(deployer.address);

        let performanceFee = await poolManagerLogic.performanceFee();
        expect(performanceFee).to.equal(1000);
    });

    it('user has too many pools', async () => {
        let tx = await registry.createPool("Pool", 1000);
        await tx.wait();

        let tx2 = await registry.createPool("Pool2", 2000);
        await tx2.wait();

        let tx3 = registry.createPool("Pool3", 3000);
        await expect(tx3).to.be.reverted;

        let userPools = await registry.userPools(deployer.address);
        expect(userPools).to.equal(2);
    });
  });

  describe("#createCappedPool", () => {
    it("pool name too long", async () => {
      let tx = registry.createCappedPool("Pool name that is too long because it contains more than 50 characters, causing the transaction to revert.", parseEther("1"), 10000, 1000);
      await expect(tx).to.be.reverted;

      let userCappedPools = await registry.userCappedPools(deployer.address);
      expect(userCappedPools).to.equal(0);
    });

    it("performance fee too high", async () => {
        let tx = registry.createCappedPool("Pool", parseEther("1"), 10000, 100000000000);
        await expect(tx).to.be.reverted;

        let userCappedPools = await registry.userCappedPools(deployer.address);
        expect(userCappedPools).to.equal(0);
    });  

    it("supply cap too high", async () => {
        let tx = registry.createCappedPool("Pool", parseEther("1"), 10000000000000, 1000);
        await expect(tx).to.be.reverted;

        let userCappedPools = await registry.userCappedPools(deployer.address);
        expect(userCappedPools).to.equal(0);
    }); 

    it("supply cap too low", async () => {
        let tx = registry.createCappedPool("Pool", parseEther("1"), 1, 1000);
        await expect(tx).to.be.reverted;

        let userCappedPools = await registry.userCappedPools(deployer.address);
        expect(userCappedPools).to.equal(0);
    }); 

    it("seed price too high", async () => {
        let tx = registry.createCappedPool("Pool", parseEther("10000000000000"), 10000, 1000);
        await expect(tx).to.be.reverted;

        let userCappedPools = await registry.userCappedPools(deployer.address);
        expect(userCappedPools).to.equal(0);
    }); 

    it("seed price too low", async () => {
        let tx = registry.createCappedPool("Pool", parseEther("0.000001"), 10000, 1000);
        await expect(tx).to.be.reverted;

        let userCappedPools = await registry.userCappedPools(deployer.address);
        expect(userCappedPools).to.equal(0);
    });

    it('meets requirements', async () => {
        let tx = await registry.createCappedPool("Pool", parseEther("1"), 10000, 1000);
        let temp = await tx.wait();
        let event = temp.events[temp.events.length - 1];
        poolAddress = event.args.poolAddress;
        poolManagerLogicAddress = event.args.poolManagerLogicAddress;
        cappedPool = CappedPoolFactory.attach(poolAddress);
        poolManagerLogic = PoolManagerLogicFactory.attach(poolManagerLogicAddress);

        let userCappedPools = await registry.userCappedPools(deployer.address);
        expect(userCappedPools).to.equal(1);

        let name = await cappedPool.name();
        expect(name).to.equal("Pool");

        let manager = await cappedPool.manager();
        expect(manager).to.equal(deployer.address);

        let seedPrice = await cappedPool.seedPrice();
        expect(seedPrice).to.equal(parseEther("1"));

        let maxSupply = await cappedPool.maxSupply();
        expect(maxSupply).to.equal(10000);

        let assignedPoolManagerLogicAddress = await poolManagerLogicFactoryContract.poolManagerLogics(poolAddress);
        expect(assignedPoolManagerLogicAddress).to.equal(poolManagerLogicAddress);

        let poolManagerLogicManager = await poolManagerLogic.manager();
        expect(poolManagerLogicManager).to.equal(deployer.address);

        let performanceFee = await poolManagerLogic.performanceFee();
        expect(performanceFee).to.equal(1000);
    });

    it('user has too many pools', async () => {
        let tx = await registry.createCappedPool("Pool", parseEther("1"), 10000, 1000);
        await tx.wait();

        let tx2 = await registry.createCappedPool("Pool2", parseEther("2"), 10000, 2000);
        await tx2.wait();

        let tx3 = registry.createCappedPool("Pool3", parseEther("3"), 10000, 3000);
        await expect(tx3).to.be.reverted;

        let userCappedPools = await registry.userCappedPools(deployer.address);
        expect(userCappedPools).to.equal(2);
    });
  });
});*/