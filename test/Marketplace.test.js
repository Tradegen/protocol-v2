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

    let tx1 = await addressResolver.setContractAddress("TGEN", tradegenTokenAddress);
    await tx1.wait();

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

    let tx20 = await assetHandler.setStableCoinAddress(stablecoinAddress);
    await tx20.wait();
  });

  beforeEach(async () => {
    marketplace = await MarketplaceFactory.deploy(addressResolverAddress);
    await marketplace.deployed();
    marketplaceAddress = marketplace.address;

    registry = await RegistryFactory.deploy(addressResolverAddress);
    await registry.deployed();
    registryAddress = registry.address;

    let tx = await addressResolver.setContractAddress("Marketplace", marketplaceAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("Registry", registryAddress);
    await tx2.wait();

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
    poolManagerLogicAddress2 = event2.args.poolManagerLogicAddress;
    cappedPool2 = CappedPoolFactory.attach(cappedPoolAddress2);
    poolManagerLogic2 = PoolManagerLogicFactory.attach(poolManagerLogicAddress2);

    let tx22 = await registry.connect(otherUser).createCappedPool("Capped Pool 3", parseEther("1"), 1000, 1000);
    let temp3 = await tx22.wait();
    let event3 = temp3.events[temp3.events.length - 1];
    cappedPoolAddress3 = event3.args.poolAddress;
    poolManagerLogicAddress3 = event3.args.poolManagerLogicAddress;
    cappedPool3 = CappedPoolFactory.attach(cappedPoolAddress3);
    poolManagerLogic3 = PoolManagerLogicFactory.attach(poolManagerLogicAddress3);

    let tx23 = await registry.connect(otherUser).createCappedPool("Capped Pool 4", parseEther("1"), 1000, 1000);
    let temp4 = await tx23.wait();
    let event4 = temp4.events[temp4.events.length - 1];
    cappedPoolAddress4 = event4.args.poolAddress;
    poolManagerLogicAddress4 = event4.args.poolManagerLogicAddress;
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
  
  describe("#createListing", () => {
    it("not valid pool", async () => {
        let tx = marketplace.createListing(deployer.address, 1, 10, parseEther("10"));
        await expect(tx).to.be.reverted;

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(0);
    });  

    it("wrong token class", async () => {
        let tx = marketplace.createListing(cappedPoolAddress1, 10, 10, parseEther("10"));
        await expect(tx).to.be.reverted;

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(0);
    });

    it("not enough tokens", async () => {
        let tx = marketplace.createListing(cappedPoolAddress1, 1, 800, parseEther("10"));
        await expect(tx).to.be.reverted;

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(0);
    });

    it("meets requirements", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(1);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(40);

        let balanceOfMarketplace = await cappedPoolNFT.balanceOf(marketplaceAddress, 1);
        expect(balanceOfMarketplace).to.equal(10);

        let listingIndex = await marketplace.getListingIndex(deployer.address, cappedPoolAddress1);
        expect(listingIndex).to.equal(1);

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[0]).to.be.true;
        expect(listing[1]).to.equal(cappedPoolAddress1);
        expect(listing[2]).to.equal(deployer.address);
        expect(listing[3]).to.equal(1);
        expect(listing[4]).to.equal(10);
        expect(listing[5]).to.equal(parseEther("10"));
    });

    it("already have listing for the same pool", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.createListing(cappedPoolAddress1, 2, 10, parseEther("5"));
        await expect(tx3).to.be.reverted;

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(1);
    });

    it("meets requirements; different pools from same user", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        cappedPoolNFTAddress = cappedPool2.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx3 = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx3.wait();

        let tx4 = await marketplace.createListing(cappedPoolAddress2, 2, 5, parseEther("8"));
        await tx4.wait();

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(2);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOfDeployer).to.equal(45);

        let balanceOfMarketplace = await cappedPoolNFT.balanceOf(marketplaceAddress, 2);
        expect(balanceOfMarketplace).to.equal(5);

        let listingIndex1 = await marketplace.getListingIndex(deployer.address, cappedPoolAddress1);
        expect(listingIndex1).to.equal(1);

        let listingIndex2 = await marketplace.getListingIndex(deployer.address, cappedPoolAddress2);
        expect(listingIndex2).to.equal(2);

        let listing1 = await marketplace.getMarketplaceListing(1);
        expect(listing1[0]).to.be.true;
        expect(listing1[1]).to.equal(cappedPoolAddress1);
        expect(listing1[2]).to.equal(deployer.address);
        expect(listing1[3]).to.equal(1);
        expect(listing1[4]).to.equal(10);
        expect(listing1[5]).to.equal(parseEther("10"));

        let listing2 = await marketplace.getMarketplaceListing(2);
        expect(listing2[0]).to.be.true;
        expect(listing2[1]).to.equal(cappedPoolAddress2);
        expect(listing2[2]).to.equal(deployer.address);
        expect(listing2[3]).to.equal(2);
        expect(listing2[4]).to.equal(5);
        expect(listing2[5]).to.equal(parseEther("8"));
    });

    it("meets requirements; same pool with different users", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = await cappedPoolNFT.connect(otherUser).setApprovalForAll(marketplaceAddress, true);
        await tx3.wait();

        let tx4 = await marketplace.connect(otherUser).createListing(cappedPoolAddress1, 2, 5, parseEther("8"));
        await tx4.wait();

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(2);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(40);

        let balanceOfOther = await cappedPoolNFT.balanceOf(otherUser.address, 2);
        expect(balanceOfOther).to.equal(45);

        let balanceOfMarketplace1 = await cappedPoolNFT.balanceOf(marketplaceAddress, 1);
        expect(balanceOfMarketplace1).to.equal(10);

        let balanceOfMarketplace2 = await cappedPoolNFT.balanceOf(marketplaceAddress, 2);
        expect(balanceOfMarketplace2).to.equal(5);

        let listingIndex1 = await marketplace.getListingIndex(deployer.address, cappedPoolAddress1);
        expect(listingIndex1).to.equal(1);

        let listingIndex2 = await marketplace.getListingIndex(otherUser.address, cappedPoolAddress1);
        expect(listingIndex2).to.equal(2);

        let listing1 = await marketplace.getMarketplaceListing(1);
        expect(listing1[0]).to.be.true;
        expect(listing1[1]).to.equal(cappedPoolAddress1);
        expect(listing1[2]).to.equal(deployer.address);
        expect(listing1[3]).to.equal(1);
        expect(listing1[4]).to.equal(10);
        expect(listing1[5]).to.equal(parseEther("10"));

        let listing2 = await marketplace.getMarketplaceListing(2);
        expect(listing2[0]).to.be.true;
        expect(listing2[1]).to.equal(cappedPoolAddress1);
        expect(listing2[2]).to.equal(otherUser.address);
        expect(listing2[3]).to.equal(2);
        expect(listing2[4]).to.equal(5);
        expect(listing2[5]).to.equal(parseEther("8"));
    });
  });
  
  describe("#removeListing", () => {
    it("not valid pool", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.removeListing(deployer.address, 1);
        await expect(tx3).to.be.reverted;

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(1);
    });  

    it("index out of range", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.removeListing(cappedPoolAddress1, 10);
        await expect(tx3).to.be.reverted;

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(1);
    });

    it("not seller", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.connect(otherUser).removeListing(cappedPoolAddress1, 1);
        await expect(tx3).to.be.reverted;

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(1);
    });

    it("meets requirements", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = await marketplace.removeListing(cappedPoolAddress1, 1);
        await tx3.wait();

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(1);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(50);

        let balanceOfMarketplace = await cappedPoolNFT.balanceOf(marketplaceAddress, 1);
        expect(balanceOfMarketplace).to.equal(0);

        let listingIndex = await marketplace.getListingIndex(deployer.address, cappedPoolAddress1);
        expect(listingIndex).to.equal(0);

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[0]).to.be.false;
        expect(listing[1]).to.equal(cappedPoolAddress1);
        expect(listing[2]).to.equal(deployer.address);
        expect(listing[3]).to.equal(1);
        expect(listing[4]).to.equal(0);
        expect(listing[5]).to.equal(parseEther("10"));
    });

    it("meets requirements; different pools from same user", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        cappedPoolNFTAddress = cappedPool2.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx3 = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx3.wait();

        let tx4 = await marketplace.createListing(cappedPoolAddress2, 2, 5, parseEther("8"));
        await tx4.wait();

        let tx5 = await marketplace.removeListing(cappedPoolAddress2, 2);
        await tx5.wait();

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(2);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOfDeployer).to.equal(50);

        let balanceOfMarketplace = await cappedPoolNFT.balanceOf(marketplaceAddress, 2);
        expect(balanceOfMarketplace).to.equal(0);

        let listingIndex1 = await marketplace.getListingIndex(deployer.address, cappedPoolAddress1);
        expect(listingIndex1).to.equal(1);

        let listingIndex2 = await marketplace.getListingIndex(deployer.address, cappedPoolAddress2);
        expect(listingIndex2).to.equal(0);

        let listing1 = await marketplace.getMarketplaceListing(1);
        expect(listing1[0]).to.be.true;
        expect(listing1[1]).to.equal(cappedPoolAddress1);
        expect(listing1[2]).to.equal(deployer.address);
        expect(listing1[3]).to.equal(1);
        expect(listing1[4]).to.equal(10);
        expect(listing1[5]).to.equal(parseEther("10"));

        let listing2 = await marketplace.getMarketplaceListing(2);
        expect(listing2[0]).to.be.false;
        expect(listing2[1]).to.equal(cappedPoolAddress2);
        expect(listing2[2]).to.equal(deployer.address);
        expect(listing2[3]).to.equal(2);
        expect(listing2[4]).to.equal(0);
        expect(listing2[5]).to.equal(parseEther("8"));
    });

    it("meets requirements; same pool with different users", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = await cappedPoolNFT.connect(otherUser).setApprovalForAll(marketplaceAddress, true);
        await tx3.wait();

        let tx4 = await marketplace.connect(otherUser).createListing(cappedPoolAddress1, 2, 5, parseEther("8"));
        await tx4.wait();

        let tx5 = await marketplace.connect(otherUser).removeListing(cappedPoolAddress1, 2);
        await tx5.wait();

        let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
        expect(numberOfMarketplaceListings).to.equal(2);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(40);

        let balanceOfOther = await cappedPoolNFT.balanceOf(otherUser.address, 2);
        expect(balanceOfOther).to.equal(50);

        let balanceOfMarketplace1 = await cappedPoolNFT.balanceOf(marketplaceAddress, 1);
        expect(balanceOfMarketplace1).to.equal(10);

        let balanceOfMarketplace2 = await cappedPoolNFT.balanceOf(marketplaceAddress, 2);
        expect(balanceOfMarketplace2).to.equal(0);

        let listingIndex1 = await marketplace.getListingIndex(deployer.address, cappedPoolAddress1);
        expect(listingIndex1).to.equal(1);

        let listingIndex2 = await marketplace.getListingIndex(otherUser.address, cappedPoolAddress1);
        expect(listingIndex2).to.equal(0);

        let listing1 = await marketplace.getMarketplaceListing(1);
        expect(listing1[0]).to.be.true;
        expect(listing1[1]).to.equal(cappedPoolAddress1);
        expect(listing1[2]).to.equal(deployer.address);
        expect(listing1[3]).to.equal(1);
        expect(listing1[4]).to.equal(10);
        expect(listing1[5]).to.equal(parseEther("10"));

        let listing2 = await marketplace.getMarketplaceListing(2);
        expect(listing2[0]).to.be.false;
        expect(listing2[1]).to.equal(cappedPoolAddress1);
        expect(listing2[2]).to.equal(otherUser.address);
        expect(listing2[3]).to.equal(2);
        expect(listing2[4]).to.equal(0);
        expect(listing2[5]).to.equal(parseEther("8"));
    });
  });
  
  describe("#updatePrice", () => {
    it("not valid pool", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.updatePrice(deployer.address, 1, parseEther("88"));
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[5]).to.equal(parseEther("10"));
    });  

    it("index out of range", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.updatePrice(cappedPoolAddress1, 1000, parseEther("88"));
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[5]).to.equal(parseEther("10"));
    });

    it("not seller", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.connect(otherUser).updatePrice(cappedPoolAddress1, 1, parseEther("88"));
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[5]).to.equal(parseEther("10"));
    });

    it("meets requirements", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = await marketplace.updatePrice(cappedPoolAddress1, 1, parseEther("88"));
        await tx3.wait();

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[5]).to.equal(parseEther("88"));
    });
  });

  describe("#updateQuantity", () => {
    it("not valid pool", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.updateQuantity(deployer.address, 1, 30);
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(10);
    });  

    it("index out of range", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.updateQuantity(cappedPoolAddress1, 10, 30);
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(10);
    });

    it("not seller", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.connect(otherUser).updateQuantity(cappedPoolAddress1, 1, 30);
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(10);
    });

    it("quantity out of bounds", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.updateQuantity(cappedPoolAddress1, 1, 300);
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(10);
    });

    it("meets requirements; new > old", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx3.wait();

        let tx4 = await marketplace.updateQuantity(cappedPoolAddress1, 1, 20);
        await tx4.wait();

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(20);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(30);

        let balanceOfMarketplace = await cappedPoolNFT.balanceOf(marketplaceAddress, 1);
        expect(balanceOfMarketplace).to.equal(20);
    });

    it("meets requirements; new < old", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = await marketplace.updateQuantity(cappedPoolAddress1, 1, 5);
        await tx3.wait();

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(5);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(45);

        let balanceOfMarketplace = await cappedPoolNFT.balanceOf(marketplaceAddress, 1);
        expect(balanceOfMarketplace).to.equal(5);
    });
  });
  
  describe("#purchase", () => {
    it("not valid pool", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.connect(otherUser).purchase(deployer.address, 1, 5);
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(10);
    });  

    it("index out of range", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.connect(otherUser).purchase(cappedPoolAddress1, 5, 3);
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(10);
    });

    it("listing does not exist", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = await marketplace.removeListing(cappedPoolAddress1, 1);
        await tx3.wait();

        let tx4 = marketplace.connect(otherUser).purchase(cappedPoolAddress1, 5, 3);
        await expect(tx4).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(00);
    });

    it("cannot buy your own position", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = marketplace.purchase(cappedPoolAddress1, 1, 3);
        await expect(tx3).to.be.reverted;

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(10);
    });

    it("meets requirements; partial", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 10, parseEther("10"));
        await tx2.wait();

        let tx3 = await stablecoin.connect(otherUser).approve(marketplaceAddress, parseEther("10"));
        await tx3.wait();

        let initialBalanceStaking = await tradegenToken.balanceOf(addressResolverAddress);
        let initialBalanceDeployer = await stablecoin.balanceOf(deployer.address);
        let initialBalanceOther = await stablecoin.balanceOf(otherUser.address);

        let tx4 = await marketplace.connect(otherUser).purchase(cappedPoolAddress1, 1, 1);
        await tx4.wait();

        let newBalanceStaking = await tradegenToken.balanceOf(addressResolverAddress);
        let newBalanceDeployer = await stablecoin.balanceOf(deployer.address);
        let newBalanceOther = await stablecoin.balanceOf(otherUser.address);
        let expectedNewBalanceStaking = BigInt(initialBalanceStaking) + BigInt(parseEther("1"));
        let expectedNewBalanceDeployer = BigInt(initialBalanceDeployer) + BigInt(parseEther("9.9"));
        let expectedNewBalanceOther = BigInt(initialBalanceOther) - BigInt(parseEther("10"));
        expect(newBalanceStaking.toString()).to.equal(expectedNewBalanceStaking.toString());
        expect(newBalanceDeployer.toString()).to.equal(expectedNewBalanceDeployer.toString());
        expect(newBalanceOther.toString()).to.equal(expectedNewBalanceOther.toString());

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[4]).to.equal(9);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(40);

        let balanceOfMarketplace = await cappedPoolNFT.balanceOf(marketplaceAddress, 1);
        expect(balanceOfMarketplace).to.equal(9);

        let balanceOfOther = await cappedPoolNFT.balanceOf(otherUser.address, 1);
        expect(balanceOfOther).to.equal(1);
    });

    it("meets requirements; full", async () => {
        cappedPoolNFTAddress = cappedPool1.getNFTAddress();
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);

        let tx = await cappedPoolNFT.setApprovalForAll(marketplaceAddress, true);
        await tx.wait();

        let tx2 = await marketplace.createListing(cappedPoolAddress1, 1, 1, parseEther("10"));
        await tx2.wait();

        let tx3 = await stablecoin.connect(otherUser).approve(marketplaceAddress, parseEther("10"));
        await tx3.wait();

        let initialBalanceStaking = await tradegenToken.balanceOf(addressResolverAddress);
        let initialBalanceDeployer = await stablecoin.balanceOf(deployer.address);
        let initialBalanceOther = await stablecoin.balanceOf(otherUser.address);

        let tx4 = await marketplace.connect(otherUser).purchase(cappedPoolAddress1, 1, 1);
        await tx4.wait();

        let newBalanceStaking = await tradegenToken.balanceOf(addressResolverAddress);
        let newBalanceDeployer = await stablecoin.balanceOf(deployer.address);
        let newBalanceOther = await stablecoin.balanceOf(otherUser.address);
        let expectedNewBalanceStaking = BigInt(initialBalanceStaking) + BigInt(parseEther("1"));
        let expectedNewBalanceDeployer = BigInt(initialBalanceDeployer) + BigInt(parseEther("9.9"));
        let expectedNewBalanceOther = BigInt(initialBalanceOther) - BigInt(parseEther("10"));
        expect(newBalanceStaking.toString()).to.equal(expectedNewBalanceStaking.toString());
        expect(newBalanceDeployer.toString()).to.equal(expectedNewBalanceDeployer.toString());
        expect(newBalanceOther.toString()).to.equal(expectedNewBalanceOther.toString());

        let listing = await marketplace.getMarketplaceListing(1);
        expect(listing[0]).to.be.false;
        expect(listing[4]).to.equal(0);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(49);

        let balanceOfMarketplace = await cappedPoolNFT.balanceOf(marketplaceAddress, 1);
        expect(balanceOfMarketplace).to.equal(0);

        let balanceOfOther = await cappedPoolNFT.balanceOf(otherUser.address, 1);
        expect(balanceOfOther).to.equal(1);
    });
  });
});