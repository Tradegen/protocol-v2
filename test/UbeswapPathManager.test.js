const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("UbeswapPathManager", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let testToken1;
  let testTokenAddress1;
  let testToken2;
  let testTokenAddress2;
  let testToken3;
  let testTokenAddress3;
  let TestTokenFactory;

  let ubeswapPathManager;
  let ubeswapPathManagerAddress;
  let UbeswapPathManagerFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    TestTokenFactory = await ethers.getContractFactory('TestTokenERC20');
    UbeswapPathManagerFactory = await ethers.getContractFactory('UbeswapPathManager');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    testToken1 = await TestTokenFactory.deploy("Token 1", "ONE");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    testToken2 = await TestTokenFactory.deploy("Token 2", "TWO");
    await testToken2.deployed();
    testTokenAddress2 = testToken2.address;

    testToken3 = await TestTokenFactory.deploy("Token 3", "THREE");
    await testToken3.deployed();
    testTokenAddress3 = testToken3.address;

    let tx = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx.wait();
  });

  beforeEach(async () => {
    ubeswapPathManager = await UbeswapPathManagerFactory.deploy(addressResolverAddress);
    await ubeswapPathManager.deployed();
    ubeswapPathManagerAddress = ubeswapPathManager.address;

    let tx = await addressResolver.setContractAddress("UbeswapPathManager", ubeswapPathManagerAddress);
    await tx.wait();
  });
  
  describe("#setPath", () => {
    it("onlyOwner", async () => {
      let tx = ubeswapPathManager.connect(otherUser).setPath(testTokenAddress1, testTokenAddress2, [testTokenAddress1, testTokenAddress2]);
      await expect(tx).to.be.reverted;
    });

    it("set path with unsupported asset", async () => {
        let tx = await assetHandler.setValidAsset(testTokenAddress1, 1);
        await tx.wait();

        let tx2 = ubeswapPathManager.setPath(testTokenAddress1, testTokenAddress3, [testTokenAddress1, testTokenAddress3]);
        await expect(tx2).to.be.reverted;
      });

    it('set path with supported assets', async () => {
        let tx = await assetHandler.setValidAsset(testTokenAddress1, 1);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(testTokenAddress2, 1);
        await tx2.wait();

        let tx3 = await ubeswapPathManager.setPath(testTokenAddress1, testTokenAddress2, [testTokenAddress1, testTokenAddress2]);
        await tx3.wait();

        expect(tx3).to.emit(ubeswapPathManager, "SetPath");

        let path = await ubeswapPathManager.getPath(testTokenAddress1, testTokenAddress2);
        expect(path.length).to.equal(2);
        expect(path[0]).to.equal(testTokenAddress1);
        expect(path[1]).to.equal(testTokenAddress2);
    });
  });
});*/