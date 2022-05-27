const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("UbeswapLPTokenPriceCalculator", () => {
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

  let uniswapPair;
  let uniswapPairAddress;
  let UniswapPairFactory;

  let testToken1;
  let testToken2;
  let mockPair;
  let testTokenAddress1;
  let testTokenAddress2;
  let mockPairAddress;
  let TokenFactory;

  let ubeswapLPTokenPriceCalculator;
  let ubeswapLPTokenPriceCalculatorAddress;
  let UbeswapLPTokenPriceCalculatorFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    UbeswapAdapterFactory = await ethers.getContractFactory('TestUbeswapAdapter');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    UniswapPairFactory = await ethers.getContractFactory('UniswapPair');
    UbeswapLPTokenPriceCalculatorFactory = await ethers.getContractFactory('UbeswapLPTokenPriceCalculator');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    ubeswapAdapter = await UbeswapAdapterFactory.deploy();
    await ubeswapAdapter.deployed();
    ubeswapAdapterAddress = ubeswapAdapter.address;

    uniswapPair = await UniswapPairFactory.deploy();
    await uniswapPair.deployed();
    uniswapPairAddress = uniswapPair.address;

    testToken1 = await TokenFactory.deploy("Test Token 1", "TEST1");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    testToken2 = await TokenFactory.deploy("Test Token 2", "TEST2");
    await testToken2.deployed();
    testTokenAddress2 = testToken2.address;

    mockPair = await TokenFactory.deploy("Pair", "LP");
    await mockPair.deployed();
    mockPairAddress = mockPair.address;

    let tx = await addressResolver.setContractAddress("UbeswapAdapter", ubeswapAdapterAddress);
    await tx.wait();

    let tx2 = await ubeswapAdapter.setPrice(testTokenAddress1, parseEther("5"));
    await tx2.wait();

    let tx3 = await ubeswapAdapter.setPrice(testTokenAddress2, parseEther("1"));
    await tx3.wait();
  });

  beforeEach(async () => {
    ubeswapLPTokenPriceCalculator = await UbeswapLPTokenPriceCalculatorFactory.deploy(addressResolverAddress);
    await ubeswapLPTokenPriceCalculator.deployed();
    ubeswapLPTokenPriceCalculatorAddress = ubeswapLPTokenPriceCalculator.address;
  });
  
  describe("#getUSDPrice", () => {
    it("get price of supported pair", async () => {
        let tx = await uniswapPair.setToken0(mockPairAddress, testTokenAddress1);
        await tx.wait();

        let tx2 = await uniswapPair.setToken1(mockPairAddress, testTokenAddress2);
        await tx2.wait();

        let tx3 = await uniswapPair.setTotalSupply(mockPairAddress, parseEther("10"));
        await tx3.wait();

        let tx4 = await uniswapPair.setReserve0(mockPairAddress, parseEther("5"));
        await tx4.wait();

        let tx5 = await uniswapPair.setReserve1(mockPairAddress, parseEther("5"));
        await tx5.wait();

        const price = await ubeswapLPTokenPriceCalculator.getUSDPrice(mockPairAddress);
        expect(price).to.equal(parseEther("5"))
    });
  });
});