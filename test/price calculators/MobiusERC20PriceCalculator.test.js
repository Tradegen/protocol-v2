const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("MobiusERC20PriceCalculator", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let mobiusAdapter;
  let mobiusAdapterAddress;
  let MobiusAdapterFactory;

  let testToken1;
  let testTokenAddress1;
  let TokenFactory;

  let mobiusERC20PriceCalculator;
  let mobiusERC20PriceCalculatorAddress;
  let MobiusERC20PriceCalculatorFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    MobiusAdapterFactory = await ethers.getContractFactory('TestMobiusAdapter');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    MobiusERC20PriceCalculatorFactory = await ethers.getContractFactory('MobiusERC20PriceCalculator');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    mobiusAdapter = await MobiusAdapterFactory.deploy();
    await mobiusAdapter.deployed();
    mobiusAdapterAddress = mobiusAdapter.address;

    testToken1 = await TokenFactory.deploy("Test Token 1", "TEST1");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    let tx = await addressResolver.setContractAddress("MobiusAdapter", mobiusAdapterAddress);
    await tx.wait();
  });

  beforeEach(async () => {
    mobiusERC20PriceCalculator = await MobiusERC20PriceCalculatorFactory.deploy(addressResolverAddress);
    await mobiusERC20PriceCalculator.deployed();
    mobiusERC20PriceCalculatorAddress = mobiusERC20PriceCalculator.address;
  });
  
  describe("#getUSDPrice", () => {
    it("get price of supported asset", async () => {
        let tx = await mobiusAdapter.setPrice(testTokenAddress1, parseEther("1"));
        await tx.wait();

        const price = await mobiusERC20PriceCalculator.getUSDPrice(testTokenAddress1);
        expect(price).to.equal(parseEther("1"));
    });

    it("get price of unsupported asset", async () => {
      let tx = mobiusERC20PriceCalculator.getUSDPrice(otherUser.address);
      await expect(tx).to.be.reverted;
    });
  });
});*/