const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("AssetHandler", () => {
  let deployer;
  let otherUser;

  let testToken1;
  let testToken2;
  let mockStablecoin;
  let testTokenAddress1;
  let testTokenAddress2;
  let mockStablecoinAddress;
  let TokenFactory;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let verifier;
  let verifierAddress;
  let VerifierFactory;

  let priceCalculator;
  let priceCalculatorAddress;
  let PriceCalculatorFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    VerifierFactory = await ethers.getContractFactory('TestAssetVerifier');
    PriceCalculatorFactory = await ethers.getContractFactory('TestPriceCalculator');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    verifier = await VerifierFactory.deploy();
    await verifier.deployed();
    verifierAddress = verifier.address;

    priceCalculator = await PriceCalculatorFactory.deploy();
    await priceCalculator.deployed();
    priceCalculatorAddress = priceCalculator.address;

    testToken1 = await TokenFactory.deploy("Test Token 1", "TEST1");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    testToken2 = await TokenFactory.deploy("Test Token 2", "TEST2");
    await testToken2.deployed();
    testTokenAddress2 = testToken2.address;

    mockStablecoin = await TokenFactory.deploy("Stablecoin", "SGD");
    await mockStablecoin.deployed();
    mockStablecoinAddress = mockStablecoin.address;

    let tx = await addressResolver.setAssetVerifier(1, verifierAddress);
    await tx.wait();
  });

  beforeEach(async () => {
    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    let tx = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx.wait();
  });
  
  describe("#setStableCoinAddress", () => {
    it("onlyOwner", async () => {
        let tx = assetHandler.connect(otherUser).setStableCoinAddress(mockStablecoinAddress);
        await expect(tx).to.be.reverted;
    });

    it('set stable coin address', async () => {
        let tx = await assetHandler.setStableCoinAddress(mockStablecoinAddress);
        await tx.wait();
        expect(tx).to.emit(assetHandler, "UpdatedStableCoinAddress");

        let address = await assetHandler.getStablecoinAddress();
        expect(address).to.equal(mockStablecoinAddress);
    });
  });
  
  describe("#addCurrencyKey", () => {
    it("onlyOwner", async () => {
      let tx = assetHandler.connect(otherUser).addCurrencyKey(1, testTokenAddress1);
      await expect(tx).to.be.reverted;

      let assetType = await assetHandler.assetTypes(testTokenAddress1);
      expect(assetType).to.equal(0);
    });
    
    it('add ERC20 asset', async () => {
      let tx = await assetHandler.addCurrencyKey(1, testTokenAddress1);
      await tx.wait();
      expect(tx).to.emit(assetHandler, "AddedAsset");

      let tx2 = await verifier.setBalance(deployer.address, testTokenAddress1, parseEther("1"));
      await tx2.wait();

      const isValid = await assetHandler.isValidAsset(testTokenAddress1);
      expect(isValid).to.be.true;

      const assetType = await assetHandler.getAssetType(testTokenAddress1);
      expect(assetType).to.equal(1);

      const assets = await assetHandler.getAvailableAssetsForType(1);
      expect(assets.length).to.equal(1);
      expect(assets[0]).to.equal(testTokenAddress1);

      const verifier = await assetHandler.getVerifier(testTokenAddress1);
      expect(verifier).to.equal(verifierAddress);

      const decimals = await assetHandler.getDecimals(testTokenAddress1);
      expect(decimals).to.equal(18);

      const balance = await assetHandler.getBalance(deployer.address, testTokenAddress1);
      expect(balance).to.be.equal(parseEther("1"));
    });
  });

  describe("#removeCurrencyKey", () => {
    it("onlyOwner", async () => {
      let tx = await assetHandler.addCurrencyKey(1, testTokenAddress1);
      await tx.wait();

      let tx2 = assetHandler.connect(otherUser).removeCurrencyKey(1, testTokenAddress1);
      await expect(tx2).to.be.reverted;

      let assetType = await assetHandler.assetTypes(testTokenAddress1);
      expect(assetType).to.equal(1);
    });

    it("assetExists", async () => {
      let tx = assetHandler.removeCurrencyKey(1, testTokenAddress1);
      await expect(tx).to.be.reverted;
    });
    
    it('remove one ERC20 asset from end', async () => {
      let tx = await assetHandler.addCurrencyKey(1, testTokenAddress1);
      await tx.wait();

      let tx2 = await assetHandler.removeCurrencyKey(1, testTokenAddress1);
      await tx2.wait();

      const assets = await assetHandler.getAvailableAssetsForType(1);
      expect(assets.length).to.equal(0);

      const isValid = await assetHandler.isValidAsset(testTokenAddress1);
      expect(isValid).to.be.false;
    });

    it('remove one ERC20 asset from start', async () => {
      let tx = await assetHandler.addCurrencyKey(1, testTokenAddress1);
      await tx.wait();

      let tx2 = await assetHandler.addCurrencyKey(1, testTokenAddress2);
      await tx2.wait();

      let tx3 = await assetHandler.removeCurrencyKey(1, testTokenAddress1);
      await tx3.wait();

      const assets = await assetHandler.getAvailableAssetsForType(1);
      expect(assets.length).to.equal(1);
      expect(assets[0]).to.equal(testTokenAddress2);

      const isValid = await assetHandler.isValidAsset(testTokenAddress1);
      expect(isValid).to.be.false;

      const isValid2 = await assetHandler.isValidAsset(testTokenAddress2);
      expect(isValid2).to.be.true;
    });
  });
  
  describe("#addAssetType", () => {
    it("onlyOwner", async () => {
      let tx = assetHandler.connect(otherUser).addAssetType(1, priceCalculatorAddress);
      await expect(tx).to.be.reverted;
    });
    
    it('add ERC20 as asset type 1', async () => {
      let tx = await assetHandler.addAssetType(1, priceCalculatorAddress);
      await tx.wait();
      expect(tx).to.emit(assetHandler, "AddedAssetType");
    });

    it('get price of ERC20 token', async () => {
      let tx = await assetHandler.addAssetType(1, priceCalculatorAddress);
      await tx.wait();
      expect(tx).to.emit(assetHandler, "AddedAssetType");

      let tx2 = await assetHandler.addCurrencyKey(1, testTokenAddress1);
      await tx2.wait();

      let tx3 = await priceCalculator.setPrice(testTokenAddress1, parseEther("2"));
      await tx3.wait();

      const price = await assetHandler.getUSDPrice(testTokenAddress1);
      expect(price).to.be.equal(parseEther("2"));
    });
  });
});