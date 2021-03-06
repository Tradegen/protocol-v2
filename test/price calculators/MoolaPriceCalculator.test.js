const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("MoolaPriceCalculator", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let moolaAdapter;
  let moolaAdapterAddress;
  let MoolaAdapterFactory;

  let testToken1;
  let testTokenAddress1;
  let TokenFactory;

  let moolaPriceCalculator;
  let moolaPriceCalculatorAddress;
  let MoolaPriceCalculatorFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    MoolaAdapterFactory = await ethers.getContractFactory('TestMoolaAdapter');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    MoolaPriceCalculatorFactory = await ethers.getContractFactory('MoolaPriceCalculator');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    moolaAdapter = await MoolaAdapterFactory.deploy();
    await moolaAdapter.deployed();
    moolaAdapterAddress = moolaAdapter.address;

    testToken1 = await TokenFactory.deploy("Test Token 1", "TEST1");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    let tx = await addressResolver.setContractAddress("MoolaAdapter", moolaAdapterAddress);
    await tx.wait();
  });

  beforeEach(async () => {
    moolaPriceCalculator = await MoolaPriceCalculatorFactory.deploy(addressResolverAddress);
    await moolaPriceCalculator.deployed();
    moolaPriceCalculatorAddress = moolaPriceCalculator.address;
  });
  
  describe("#getUSDPrice", () => {
    it("get price of supported asset", async () => {
        let tx = await moolaAdapter.setPrice(testTokenAddress1, parseEther("1"));
        await tx.wait();

        const price = await moolaPriceCalculator.getUSDPrice(testTokenAddress1);
        expect(price).to.equal(parseEther("1"));
    });

    it("get price of unsupported asset", async () => {
      let tx = moolaPriceCalculator.getUSDPrice(otherUser.address);
      await expect(tx).to.be.reverted;
    });
  });
});*/