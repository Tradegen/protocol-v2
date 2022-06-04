const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("Marketplace", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let cappedPoolNFT;
  let cappedPoolNFTAddress;
  let CappedPoolNFTFactory;

  let cappedPool1;
  let cappedPool2;
  let cappedPool3;
  let cappedPool4;
  let cappedPoolAddress1;
  let cappedPoolAddress2;
  let cappedPoolAddress3;
  let cappedPoolAddress4;
  let CappedPoolFactory;

  let poolManagerLogic1;
  let poolManagerLogic2;
  let poolManagerLogic3;
  let poolManagerLogic4;
  let poolManagerLogicAddress1;
  let poolManagerLogicAddress2;
  let poolManagerLogicAddress3;
  let poolManagerLogicAddress4;
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

  let router;
  let routerAddress;
  let RouterFactory;

  let stablecoin;
  let tradegenToken;
  let stablecoinAddress;
  let tradegenTokenAddress;
  let TokenFactory;

  let marketplace;
  let marketplaceAddress;
  let MarketplaceFactory;

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
    RouterFactory = await ethers.getContractFactory('TestRouter');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    MarketplaceFactory = await ethers.getContractFactory('Marketplace');

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

    stablecoin = await TokenFactory.deploy("Stablecoin", "SGD");
    await stablecoin.deployed();
    stablecoinAddress = stablecoin.address;

    tradegenToken = await TokenFactory.deploy("Tradegen", "TGEN");
    await tradegenToken.deployed();
    tradegenTokenAddress = tradegenToken.address;

    router = await RouterFactory.deploy(tradegenTokenAddress, parseEther("1"));
    await router.deployed();
    routerAddress = router.address;

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

    let tx8 = await addressResolver.setContractAddress("Router", routerAddress);
    await tx8.wait();

    let tx9 = await addressResolver.setContractAddress("xTGEN", addressResolverAddress);
    await tx9.wait();

    let tx10 = await settings.setParameterValue("MaximumNumberOfPoolsPerUser", 2);
    await tx10.wait();

    let tx11 = await settings.setParameterValue("MaximumPerformanceFee", 10000);
    await tx11.wait();

    let tx12 = await settings.setParameterValue("MaximumNumberOfCappedPoolTokens", 1000000);
    await tx12.wait();

    let tx13 = await settings.setParameterValue("MinimumNumberOfCappedPoolTokens", 100);
    await tx13.wait();

    let tx14 = await settings.setParameterValue("MinimumCappedPoolSeedPrice", parseEther("0.1"));
    await tx14.wait();

    let tx15 = await settings.setParameterValue("MaximumCappedPoolSeedPrice", parseEther("1000"));
    await tx15.wait();

    let tx16 = await settings.setParameterValue("MarketplaceProtocolFee", 100);
    await tx16.wait();

    let tx17 = await settings.setParameterValue("MarketplaceAssetManagerFee", 200);
    await tx17.wait();

    let tx18 = await settings.setParameterValue("MaximumNumberOfPositionsInPool", 8);
    await tx18.wait();

    let tx19 = await tradegenToken.transfer(routerAddress, parseEther("1000"));
    await tx19.wait();

    let tx20 = await registry.createCappedPool("Capped Pool 1", parseEther("1"), 1000, 1000);
    let temp1 = await tx20.wait();
    let event1 = temp1.events[temp1.events.length - 1];
    cappedPoolAddress1 = event1.args.poolAddress;
    poolManagerLogicAddress1 = event1.args.poolManagerLogicAddress;
    cappedPool1 = CappedPoolFactory.attach(cappedPoolAddress1);
    poolManagerLogic1 = PoolManagerLogicFactory.attach(poolManagerLogicAddress1);

    let tx21 = await registry.createCappedPool("Capped Pool 2", parseEther("1"), 1000, 1000);
    let temp2 = await tx21.wait();
    let event2 = temp2.events[temp2.events.length - 1];
    cappedPoolAddress2 = event2.args.poolAddress;
    poolManagerLogicAddress2 = event1.args.poolManagerLogicAddress;
    cappedPool2 = CappedPoolFactory.attach(cappedPoolAddress2);
    poolManagerLogic2 = PoolManagerLogicFactory.attach(poolManagerLogicAddress2);

    let tx22 = await registry.connect(otherUser).createCappedPool("Capped Pool 3", parseEther("1"), 1000, 1000);
    let temp3 = await tx22.wait();
    let event3 = temp3.events[temp3.events.length - 1];
    cappedPoolAddress3 = event3.args.poolAddress;
    poolManagerLogicAddress3 = event1.args.poolManagerLogicAddress;
    cappedPool3 = CappedPoolFactory.attach(cappedPoolAddress3);
    poolManagerLogic3 = PoolManagerLogicFactory.attach(poolManagerLogicAddress3);

    let tx23 = await registry.connect(otherUser).createCappedPool("Capped Pool 4", parseEther("1"), 1000, 1000);
    let temp4 = await tx23.wait();
    let event4 = temp4.events[temp4.events.length - 1];
    cappedPoolAddress4 = event4.args.poolAddress;
    poolManagerLogicAddress4 = event1.args.poolManagerLogicAddress;
    cappedPool4 = CappedPoolFactory.attach(cappedPoolAddress4);
    poolManagerLogic4 = PoolManagerLogicFactory.attach(poolManagerLogicAddress4);

    let tx24 = await assetHandler.setValidAsset(stablecoinAddress, 1);
    await tx24.wait();

    let tx25 = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
    await tx25.wait();

    let tx26 = await poolManagerLogic1.addAvailableAsset(stablecoinAddress);
    await tx26.wait();

    let tx27 = await poolManagerLogic1.addDepositAsset(stablecoinAddress);
    await tx27.wait();

    let tx28 = await poolManagerLogic2.addAvailableAsset(stablecoinAddress);
    await tx28.wait();

    let tx29 = await poolManagerLogic2.addDepositAsset(stablecoinAddress);
    await tx29.wait();

    let tx30 = await poolManagerLogic3.connect(otherUser).addAvailableAsset(stablecoinAddress);
    await tx30.wait();

    let tx31 = await poolManagerLogic3.connect(otherUser).addDepositAsset(stablecoinAddress);
    await tx31.wait();

    let tx32 = await poolManagerLogic4.connect(otherUser).addAvailableAsset(stablecoinAddress);
    await tx32.wait();

    let tx33 = await poolManagerLogic4.connect(otherUser).addDepositAsset(stablecoinAddress);
    await tx33.wait();

    let tx34 = await stablecoin.transfer(otherUser.address, parseEther("10000"));
    await tx34.wait();

    let tx35 = await tradegenToken.transfer(otherUser.address, parseEther("10000"));
    await tx35.wait();

    let tx36 = await stablecoin.approve(cappedPoolAddress1, parseEther("1000"));
    await tx36.wait();

    let tx37 = await stablecoin.approve(cappedPoolAddress2, parseEther("1000"));
    await tx37.wait();

    let tx38 = await stablecoin.approve(cappedPoolAddress3, parseEther("1000"));
    await tx38.wait();

    let tx39 = await stablecoin.approve(cappedPoolAddress4, parseEther("1000"));
    await tx39.wait();

    let tx40 = await stablecoin.connect(otherUser).approve(cappedPoolAddress1, parseEther("1000"));
    await tx40.wait();

    let tx41 = await stablecoin.connect(otherUser).approve(cappedPoolAddress2, parseEther("1000"));
    await tx41.wait();

    let tx42 = await stablecoin.connect(otherUser).approve(cappedPoolAddress3, parseEther("1000"));
    await tx42.wait();

    let tx43 = await stablecoin.connect(otherUser).approve(cappedPoolAddress4, parseEther("1000"));
    await tx43.wait();

    let tx44 = await cappedPool1.deposit(100, stablecoinAddress);
    await tx44.wait();

    let tx45 = await cappedPool1.connect(otherUser).deposit(100, stablecoinAddress);
    await tx45.wait();

    let tx46 = await cappedPool2.deposit(100, stablecoinAddress);
    await tx46.wait();

    let tx47 = await cappedPool2.connect(otherUser).deposit(100, stablecoinAddress);
    await tx47.wait();

    let tx48 = await cappedPool3.deposit(100, stablecoinAddress);
    await tx48.wait();

    let tx49 = await cappedPool3.connect(otherUser).deposit(100, stablecoinAddress);
    await tx49.wait();

    let tx50 = await cappedPool4.deposit(100, stablecoinAddress);
    await tx50.wait();

    let tx51 = await cappedPool4.connect(otherUser).deposit(100, stablecoinAddress);
    await tx51.wait();
  });

  beforeEach(async () => {
    marketplace = await MarketplaceFactory.deploy(addressResolverAddress);
    await marketplace.deployed();
    marketplaceAddress = marketplace.address;

    let tx = await addressResolver.setContractAddress("Marketplace", marketplaceAddress);
    await tx.wait();
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
});