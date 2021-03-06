const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("UbeswapERC20PriceCalculator", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let ubeswapAdapter;
  let ubeswapAdapterAddress;
  let UbeswapAdapterFactory;

  let testToken1;
  let testToken2;
  let mockStablecoin;
  let testTokenAddress1;
  let testTokenAddress2;
  let mockStablecoinAddress;
  let TokenFactory;

  let ubeswapERC20PriceCalculator;
  let ubeswapERC20PriceCalculatorAddress;
  let UbeswapERC20PriceCalculatorFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    UbeswapAdapterFactory = await ethers.getContractFactory('TestUbeswapAdapter');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    UbeswapERC20PriceCalculatorFactory = await ethers.getContractFactory('UbeswapERC20PriceCalculator');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    ubeswapAdapter = await UbeswapAdapterFactory.deploy();
    await ubeswapAdapter.deployed();
    ubeswapAdapterAddress = ubeswapAdapter.address;

    testToken1 = await TokenFactory.deploy("Test Token 1", "TEST1");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    testToken2 = await TokenFactory.deploy("Test Token 2", "TEST2");
    await testToken2.deployed();
    testTokenAddress2 = testToken2.address;

    mockStablecoin = await TokenFactory.deploy("Stablecoin", "SGD");
    await mockStablecoin.deployed();
    mockStablecoinAddress = mockStablecoin.address;

    let tx = await addressResolver.setContractAddress("UbeswapAdapter", ubeswapAdapterAddress);
    let tx2 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);

    await tx.wait();
    await tx2.wait();

    let tx3 = await assetHandler.setStableCoinAddress(mockStablecoinAddress);
    let tx4 = await assetHandler.addCurrencyKey(1, testTokenAddress1);

    await tx3.wait();
    await tx4.wait();
  });

  beforeEach(async () => {
    ubeswapERC20PriceCalculator = await UbeswapERC20PriceCalculatorFactory.deploy(addressResolverAddress);
    await ubeswapERC20PriceCalculator.deployed();
    ubeswapERC20PriceCalculatorAddress = ubeswapERC20PriceCalculator.address;
  });
  
  describe("#getUSDPrice", () => {
    it("get price of stablecoin", async () => {
      let tx = await ubeswapAdapter.setPrice(mockStablecoinAddress, parseEther("1"));
      await tx.wait();

        const price = await ubeswapERC20PriceCalculator.getUSDPrice(mockStablecoinAddress);
        expect(price).to.equal(parseEther("1"));
    });

    it("get price of unstablecoin", async () => {
        let tx = await ubeswapAdapter.setPrice(testTokenAddress1, parseEther("5"));
        await tx.wait();

        const price = await ubeswapERC20PriceCalculator.getUSDPrice(testTokenAddress1);
        expect(price).to.equal(parseEther("5"));
    });

    it("get price of unsupported asset", async () => {
        let tx = ubeswapERC20PriceCalculator.getUSDPrice(otherUser.address);
        await expect(tx).to.be.reverted;
    });
  });
});*/