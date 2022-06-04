const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("MoolaAdapter", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let underlyingToken;
  let underlyingTokenAddress;
  let interestToken;
  let interestTokenAddress;
  let mockLendingPool;
  let mockLendingPoolAddress;
  let TokenFactory;

  let ubeswapAdapter;
  let ubeswapAdapterAddress;
  let UbeswapAdapterFactory;

  let moolaAdapter;
  let moolaAdapterAddress;
  let MoolaAdapterFactory;
  
  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    UbeswapAdapterFactory = await ethers.getContractFactory('TestUbeswapAdapter');
    MoolaAdapterFactory = await ethers.getContractFactory('MoolaAdapter');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    underlyingToken = await TokenFactory.deploy("Celo", "CELO");
    await underlyingToken.deployed();
    underlyingTokenAddress = underlyingToken.address;

    interestToken = await TokenFactory.deploy("Interest Celo", "mCELO");
    await interestToken.deployed();
    interestTokenAddress = interestToken.address;

    mockLendingPool = await TokenFactory.deploy("Test Pool", "POOL");
    await mockLendingPool.deployed();
    mockLendingPoolAddress = mockLendingPool.address;
  });

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    moolaAdapter = await MoolaAdapterFactory.deploy(addressResolverAddress);
    await moolaAdapter.deployed();
    moolaAdapterAddress = moolaAdapter.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    ubeswapAdapter = await UbeswapAdapterFactory.deploy();
    await ubeswapAdapter.deployed();
    ubeswapAdapterAddress = ubeswapAdapter.address;

    let tx = await addressResolver.setContractAddress("UbeswapAdapter", ubeswapAdapterAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx2.wait();
  });

  describe("#addMoolaAsset", () => {
    it("only owner", async () => {
        let tx = moolaAdapter.connect(otherUser).addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await expect(tx).to.be.reverted;
    });

    it("underlying asset not valid", async () => {
        let tx = moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await expect(tx).to.be.reverted;
    });

    it("interest bearing token not valid", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 5);
        await tx.wait();

        let tx2 = moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await expect(tx2).to.be.reverted;
    });

    it("meets requirements", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 5);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(interestTokenAddress, 5);
        await tx2.wait();

        let tx3 = await moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await tx3.wait();

        let interestBearingToken = await moolaAdapter.lendingPools(mockLendingPoolAddress);
        expect(interestBearingToken).to.equal(interestTokenAddress);

        let underlyingAsset = await moolaAdapter.getUnderlyingAsset(interestBearingToken);
        expect(underlyingAsset).to.equal(underlyingTokenAddress);

        let assets = await moolaAdapter.getAssetsForLendingPool(mockLendingPoolAddress);
        expect(assets[0]).to.equal(interestTokenAddress);
        expect(assets[1]).to.equal(underlyingTokenAddress);
        
    });

    it("asset already exists", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 5);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(interestTokenAddress, 5);
        await tx2.wait();

        let tx3 = await moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await tx3.wait();

        let tx4 = moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await expect(tx4).to.be.reverted;
    });
  });

  describe("#getPrice", () => {
    it("not a valid asset", async () => {
        let price = moolaAdapter.getPrice(underlyingTokenAddress);
        await expect(price).to.be.reverted;
    });

    it("asset is an interest bearing token", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 5);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(interestTokenAddress, 5);
        await tx2.wait();

        let tx3 = await moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await tx3.wait();

        let tx4 = await ubeswapAdapter.setPrice(interestTokenAddress, parseEther("5"));
        await tx4.wait();

        let price = await moolaAdapter.getPrice(interestTokenAddress);
        expect(price).to.equal(parseEther("5"));
    });

    it("asset is an underlying asset", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 5);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(interestTokenAddress, 5);
        await tx2.wait();

        let tx3 = await moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await tx3.wait();

        let tx4 = await ubeswapAdapter.setPrice(interestTokenAddress, parseEther("5"));
        await tx4.wait();

        let tx5 = await ubeswapAdapter.setPrice(underlyingTokenAddress, parseEther("42"));
        await tx5.wait();

        let price = await moolaAdapter.getPrice(underlyingTokenAddress);
        expect(price).to.equal(parseEther("5"));
    });

    it("asset is valid but is not a supported Moola asset", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 5);
        await tx.wait();

        let tx2 = await ubeswapAdapter.setPrice(underlyingTokenAddress, parseEther("42"));
        await tx2.wait();

        let price = await moolaAdapter.getPrice(underlyingTokenAddress);
        expect(price).to.equal(0);
    });
  });

  describe("#getLendingPoolAddress", () => {
    it("asset is an interest bearing token", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 5);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(interestTokenAddress, 5);
        await tx2.wait();

        let tx3 = await moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await tx3.wait();

        let address = await moolaAdapter.getLendingPoolAddress(interestTokenAddress);
        expect(address).to.equal(mockLendingPoolAddress);

        let hasLendingPool = await moolaAdapter.checkIfTokenHasLendingPool(interestTokenAddress);
        expect(hasLendingPool).to.be.true;
    });

    it("asset is an underlying asset", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 5);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(interestTokenAddress, 5);
        await tx2.wait();

        let tx3 = await moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await tx3.wait();

        let address = await moolaAdapter.getLendingPoolAddress(underlyingTokenAddress);
        expect(address).to.equal(mockLendingPoolAddress);

        let hasLendingPool = await moolaAdapter.checkIfTokenHasLendingPool(underlyingTokenAddress);
        expect(hasLendingPool).to.be.true;
    });

    it("asset is not a supported Moola asset", async () => {
        let address = await moolaAdapter.getLendingPoolAddress(underlyingTokenAddress);
        expect(address).to.equal("0x0000000000000000000000000000000000000000");
    });
  });

  describe("#getAvailableMoolaLendingPools", () => {
    it("no lending pools", async () => {
        let addresses = await moolaAdapter.getAvailableMoolaLendingPools();
        expect(addresses.length).to.equal(0);
    });

    it("one lending pool", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 3);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(interestTokenAddress, 5);
        await tx2.wait();

        let tx3 = await moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await tx3.wait();

        let addresses = await moolaAdapter.getAvailableMoolaLendingPools();
        expect(addresses.length).to.equal(1);
        expect(addresses[0]).to.equal(mockLendingPoolAddress);
    });

    it("multiple lending pools", async () => {
        let tx = await assetHandler.setValidAsset(underlyingTokenAddress, 3);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(interestTokenAddress, 5);
        await tx2.wait();

        let tx3 = await moolaAdapter.addMoolaAsset(underlyingTokenAddress, interestTokenAddress, mockLendingPoolAddress)
        await tx3.wait();

        let tx4 = await assetHandler.setValidAsset(deployer.address, 3);
        await tx4.wait();

        let tx5 = await assetHandler.setValidAsset(otherUser.address, 5);
        await tx5.wait();

        let tx6 = await moolaAdapter.addMoolaAsset(deployer.address, otherUser.address, ubeswapAdapterAddress)
        await tx6.wait();

        let addresses = await moolaAdapter.getAvailableMoolaLendingPools();
        expect(addresses.length).to.equal(2);
        expect(addresses[0]).to.equal(mockLendingPoolAddress);
        expect(addresses[1]).to.equal(ubeswapAdapterAddress);
    });
  });
});*/