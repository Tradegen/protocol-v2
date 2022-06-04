const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("MobiusLPTokenPriceCalculator", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let mobiusAdapter;
  let mobiusAdapterAddress;
  let MobiusAdapterFactory;

  let mobiusSwap;
  let mobiusSwapAddress;
  let MobiusSwapFactory;

  let testToken1;
  let testTokenAddress1;
  let TokenFactory;

  let mobiusLPTokenPriceCalculator;
  let mobiusLPTokenPriceCalculatorAddress;
  let MobiusLPTokenPriceCalculatorFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    MobiusAdapterFactory = await ethers.getContractFactory('TestMobiusAdapter');
    MobiusSwapFactory = await ethers.getContractFactory('TestMobiusSwap');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    MobiusLPTokenPriceCalculatorFactory = await ethers.getContractFactory('MobiusLPTokenPriceCalculator');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    mobiusAdapter = await MobiusAdapterFactory.deploy();
    await mobiusAdapter.deployed();
    mobiusAdapterAddress = mobiusAdapter.address;

    mobiusSwap = await MobiusSwapFactory.deploy();
    await mobiusSwap.deployed();
    mobiusSwapAddress = mobiusSwap.address;

    testToken1 = await TokenFactory.deploy("Test Token 1", "TEST1");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    let tx = await addressResolver.setContractAddress("MobiusAdapter", mobiusAdapterAddress);
    await tx.wait();
  });

  beforeEach(async () => {
    mobiusLPTokenPriceCalculator = await MobiusLPTokenPriceCalculatorFactory.deploy(addressResolverAddress);
    await mobiusLPTokenPriceCalculator.deployed();
    mobiusLPTokenPriceCalculatorAddress = mobiusLPTokenPriceCalculator.address;
  });
  
  describe("#getUSDPrice", () => {
    it("get price of supported asset", async () => {
        let tx = await mobiusSwap.setVirtualPrice(parseEther("1"));
        await tx.wait();

        let tx2 = await mobiusAdapter.setSwapAddress(mobiusSwapAddress);
        await tx2.wait();

        const price = await mobiusLPTokenPriceCalculator.getUSDPrice(testTokenAddress1);
        expect(price).to.equal(parseEther("1"));
    });

    it("get price of unsupported asset", async () => {
      let tx = mobiusLPTokenPriceCalculator.getUSDPrice(otherUser.address);
      await expect(tx).to.be.reverted;
    });
  });
});*/