const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("PoolManagerLogic", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let settings;
  let settingsAddress;
  let SettingsFactory;

  let poolManagerLogic;
  let poolManagerLogicAddress;
  let PoolManagerLogicFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    SettingsFactory = await ethers.getContractFactory('Settings');
    PoolManagerLogicFactory = await ethers.getContractFactory('PoolManagerLogic');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    settings = await SettingsFactory.deploy();
    await settings.deployed();
    settingsAddress = settings.address;

    let tx = await addressResolver.setContractAddress("Settings", settingsAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx2.wait();

    let tx3 = await settings.setParameterValue("MaximumNumberOfPositionsInPool", 3);
    await tx3.wait();

    let tx4 = await settings.setParameterValue("MaximumPerformanceFee", 10000);
    await tx4.wait();

    let tx5 = await settings.setParameterValue("MinimumTimeBetweenPerformanceFeeUpdates", 10000);
    await tx5.wait();
  });

  beforeEach(async () => {
    poolManagerLogic = await PoolManagerLogicFactory.deploy(deployer.address, 1000, addressResolverAddress);
    await poolManagerLogic.deployed();
    poolManagerLogicAddress = poolManagerLogic.address;
  });

  describe("#addAvailableAsset", () => {
    it("not manager", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = poolManagerLogic.connect(otherUser).addAvailableAsset(deployer.address);
        await expect(tx2).to.be.reverted;
    });

    it('asset not supported', async () => {
        let tx = poolManagerLogic.addAvailableAsset(assetHandlerAddress);
        await expect(tx).to.be.reverted;

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(0);
    });

    it("meets requirements", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(1);
        expect(availableAssets[0]).to.equal(deployer.address);

        let isAvailableAsset = await poolManagerLogic.isAvailableAsset(deployer.address);
        expect(isAvailableAsset).to.be.true;
    });

    it("already added", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = poolManagerLogic.addAvailableAsset(deployer.address);
        await expect(tx3).to.be.reverted;

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(1);
        expect(availableAssets[0]).to.equal(deployer.address);
    });

    it("too many positions", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(otherUser.address, 1);
        await tx2.wait();

        let tx3 = await assetHandler.setValidAsset(addressResolverAddress, 1);
        await tx3.wait();

        let tx4 = await assetHandler.setValidAsset(poolManagerLogicAddress, 1);
        await tx4.wait();

        let tx5 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx5.wait();

        let tx6 = await poolManagerLogic.addAvailableAsset(otherUser.address);
        await tx6.wait();

        let tx7 = await poolManagerLogic.addAvailableAsset(addressResolverAddress);
        await tx7.wait();

        let tx8 = poolManagerLogic.addAvailableAsset(poolManagerLogicAddress);
        await expect(tx8).to.be.reverted;

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(3);
        expect(availableAssets[0]).to.equal(deployer.address);
        expect(availableAssets[1]).to.equal(otherUser.address);
        expect(availableAssets[2]).to.equal(addressResolverAddress);
    });
  });

  describe("#removeAvailableAsset", () => {
    it("not manager", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = poolManagerLogic.connect(otherUser).removeAvailableAsset(deployer.address);
        await expect(tx3).to.be.reverted;
    });

    it('asset is not available', async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = poolManagerLogic.removeAvailableAsset(otherUser.address);
        await expect(tx3).to.be.reverted;

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(1);
    });

    it("meets requirements; 1 asset", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = await poolManagerLogic.removeAvailableAsset(deployer.address);
        await tx3.wait();

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(0);

        let isAvailableAsset = await poolManagerLogic.isAvailableAsset(deployer.address);
        expect(isAvailableAsset).to.be.false;
    });

    it("meets requirements; multiple assets", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(otherUser.address, 1);
        await tx2.wait();

        let tx3 = await assetHandler.setValidAsset(addressResolverAddress, 1);
        await tx3.wait();

        let tx4 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx4.wait();

        let tx5 = await poolManagerLogic.addAvailableAsset(otherUser.address);
        await tx5.wait();

        let tx6 = await poolManagerLogic.addAvailableAsset(addressResolverAddress);
        await tx6.wait();

        let tx7 = await poolManagerLogic.removeAvailableAsset(otherUser.address);
        await tx7.wait();

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(2);
        expect(availableAssets[0]).to.equal(deployer.address);
        expect(availableAssets[1]).to.equal(addressResolverAddress);

        let isAvailableAsset1 = await poolManagerLogic.isAvailableAsset(deployer.address);
        expect(isAvailableAsset1).to.be.true;

        let isAvailableAsset2 = await poolManagerLogic.isAvailableAsset(otherUser.address);
        expect(isAvailableAsset2).to.be.false;

        let isAvailableAsset3 = await poolManagerLogic.isAvailableAsset(addressResolverAddress);
        expect(isAvailableAsset3).to.be.true;
    });

    it("meets requirements; asset is a deposit asset", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = await poolManagerLogic.addDepositAsset(deployer.address);
        await tx3.wait();

        let tx4 = await poolManagerLogic.removeAvailableAsset(deployer.address);
        await tx4.wait();

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(0);

        let depositAssets = await poolManagerLogic.getDepositAssets();
        expect(depositAssets.length).to.equal(0);

        let isAvailableAsset = await poolManagerLogic.isAvailableAsset(deployer.address);
        expect(isAvailableAsset).to.be.false;

        let isDepositAsset = await poolManagerLogic.isDepositAsset(deployer.address);
        expect(isDepositAsset).to.be.false;
    });

    it("meets requirements; multiple deposit assets", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(otherUser.address, 1);
        await tx2.wait();

        let tx3 = await assetHandler.setValidAsset(addressResolverAddress, 1);
        await tx3.wait();

        let tx4 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx4.wait();

        let tx5 = await poolManagerLogic.addAvailableAsset(otherUser.address);
        await tx5.wait();

        let tx6 = await poolManagerLogic.addAvailableAsset(addressResolverAddress);
        await tx6.wait();

        let tx7 = await poolManagerLogic.addDepositAsset(deployer.address);
        await tx7.wait();

        let tx8 = await poolManagerLogic.addDepositAsset(otherUser.address);
        await tx8.wait();

        let tx9 = await poolManagerLogic.addDepositAsset(addressResolverAddress);
        await tx9.wait();

        let tx10 = await poolManagerLogic.removeAvailableAsset(otherUser.address);
        await tx10.wait();

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(2);
        expect(availableAssets[0]).to.equal(deployer.address);
        expect(availableAssets[1]).to.equal(addressResolverAddress);

        let depositAssets = await poolManagerLogic.getDepositAssets();
        expect(depositAssets.length).to.equal(2);
        expect(depositAssets[0]).to.equal(deployer.address);
        expect(depositAssets[1]).to.equal(addressResolverAddress);

        let isAvailableAsset1 = await poolManagerLogic.isAvailableAsset(deployer.address);
        expect(isAvailableAsset1).to.be.true;

        let isAvailableAsset2 = await poolManagerLogic.isAvailableAsset(otherUser.address);
        expect(isAvailableAsset2).to.be.false;

        let isAvailableAsset3 = await poolManagerLogic.isAvailableAsset(addressResolverAddress);
        expect(isAvailableAsset3).to.be.true;

        let isDepositAsset1 = await poolManagerLogic.isDepositAsset(deployer.address);
        expect(isDepositAsset1).to.be.true;

        let isDepositAsset2 = await poolManagerLogic.isDepositAsset(otherUser.address);
        expect(isDepositAsset2).to.be.false;

        let isDepositAsset3 = await poolManagerLogic.isDepositAsset(addressResolverAddress);
        expect(isDepositAsset3).to.be.true;
    });
  });
  
  describe("#addDepositAsset", () => {
    it("not manager", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = poolManagerLogic.connect(otherUser).addDepositAsset(deployer.address);
        await expect(tx2).to.be.reverted;
    });

    it('asset not supported', async () => {
        let tx = poolManagerLogic.addDepositAsset(deployer.address);
        await expect(tx).to.be.reverted;

        let depositAssets = await poolManagerLogic.getDepositAssets();
        expect(depositAssets.length).to.equal(0);
    });

    it("asset not available", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = poolManagerLogic.addDepositAsset(deployer.address);
        await expect(tx2).to.be.reverted;

        let depositAssets = await poolManagerLogic.getDepositAssets();
        expect(depositAssets.length).to.equal(0);
    });

    it("meets requirements", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = await poolManagerLogic.addDepositAsset(deployer.address);
        await tx3.wait();

        let depositAssets = await poolManagerLogic.getDepositAssets();
        expect(depositAssets.length).to.equal(1);
        expect(depositAssets[0]).to.equal(deployer.address);

        let isDepositAsset = await poolManagerLogic.isDepositAsset(deployer.address);
        expect(isDepositAsset).to.be.true;
    });

    it("already used for deposits", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = await poolManagerLogic.addDepositAsset(deployer.address);
        await tx3.wait();

        let tx4 = poolManagerLogic.addDepositAsset(deployer.address);
        await expect(tx4).to.be.reverted;

        let depositAssets = await poolManagerLogic.getDepositAssets();
        expect(depositAssets.length).to.equal(1);
        expect(depositAssets[0]).to.equal(deployer.address);
    });
  });

  describe("#removeDepositAsset", () => {
    it("not manager", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = await poolManagerLogic.addDepositAsset(deployer.address);
        await tx3.wait();

        let tx4 = poolManagerLogic.connect(otherUser).removeDepositAsset(deployer.address);
        await expect(tx4).to.be.reverted;
    });

    it('asset is not available', async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = poolManagerLogic.connect(otherUser).removeDepositAsset(deployer.address);
        await expect(tx2).to.be.reverted;
    });

    it("asset is not used for deposits", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = poolManagerLogic.removeDepositAsset(deployer.address);
        await expect(tx3).to.be.reverted;
    });

    it("meets requirements; 1 asset", async () => {
        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await poolManagerLogic.addAvailableAsset(deployer.address);
        await tx2.wait();

        let tx3 = await poolManagerLogic.addDepositAsset(deployer.address);
        await tx3.wait();

        let tx4 = await poolManagerLogic.removeDepositAsset(deployer.address);
        await tx4.wait();

        let availableAssets = await poolManagerLogic.getAvailableAssets();
        expect(availableAssets.length).to.equal(1);
        expect(availableAssets[0]).to.equal(deployer.address);

        let isAvailableAsset = await poolManagerLogic.isAvailableAsset(deployer.address);
        expect(isAvailableAsset).to.be.true;

        let depositAssets = await poolManagerLogic.getDepositAssets();
        expect(depositAssets.length).to.equal(0);

        let isDepositAsset = await poolManagerLogic.isDepositAsset(deployer.address);
        expect(isDepositAsset).to.be.false;
    });
  });

  describe("#setPerformanceFee", () => {
    it("not manager", async () => {
        let tx = poolManagerLogic.connect(otherUser).setPerformanceFee(2000);
        await expect(tx).to.be.reverted;

        let performanceFee = await poolManagerLogic.performanceFee();
        expect(performanceFee).to.equal(1000);
    });

    it("performance fee too high", async () => {
        let tx = poolManagerLogic.setPerformanceFee(20000);
        await expect(tx).to.be.reverted;

        let performanceFee = await poolManagerLogic.performanceFee();
        expect(performanceFee).to.equal(1000);
    });

    it("meets requirements", async () => {
        let tx = await poolManagerLogic.setPerformanceFee(2000);
        await tx.wait();

        let performanceFee = await poolManagerLogic.performanceFee();
        expect(performanceFee).to.equal(2000);
    });

    it("not enough time between updates", async () => {
        let tx = await poolManagerLogic.setPerformanceFee(2000);
        await tx.wait();

        let tx2 = poolManagerLogic.setPerformanceFee(3000);
        await expect(tx2).to.be.reverted;

        let performanceFee = await poolManagerLogic.performanceFee();
        expect(performanceFee).to.equal(2000);
    });
  });
});