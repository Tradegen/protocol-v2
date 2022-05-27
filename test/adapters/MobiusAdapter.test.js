const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("MobiusAdapter", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let mobiusToken;
  let mobiusTokenAddress;
  let underlyingToken;
  let underlyingTokenAddress;
  let stakingToken;
  let stakingTokenAddress;
  let TokenFactory;

  let ubeswapAdapter;
  let ubeswapAdapterAddress;
  let UbeswapAdapterFactory;

  let mobiusSwap;
  let mobiusSwapAddress;
  let MobiusSwapFactory;

  let mobiusMasterMind;
  let mobiusMasterMindAddress;
  let MobiusMasterMindFactory;

  let mobiusAdapter;
  let mobiusAdapterAddress;
  let MobiusAdapterFactory;
  
  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    UbeswapAdapterFactory = await ethers.getContractFactory('TestUbeswapAdapter');
    MobiusSwapFactory = await ethers.getContractFactory('TestMobiusSwap');
    MobiusMasterMindFactory = await ethers.getContractFactory('TestMobiusMasterMind');
    MobiusAdapterFactory = await ethers.getContractFactory('MobiusAdapter');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    underlyingToken = await TokenFactory.deploy("Underlying", "UND");
    await underlyingToken.deployed();
    underlyingTokenAddress = underlyingToken.address;

    mobiusToken = await TokenFactory.deploy("Mobius", "MOB");
    await mobiusToken.deployed();
    mobiusTokenAddress = mobiusToken.address;

    stakingToken = await TokenFactory.deploy("Staking", "STK");
    await stakingToken.deployed();
    stakingTokenAddress = stakingToken.address;

    ubeswapAdapter = await UbeswapAdapterFactory.deploy(addressResolverAddress);
    await ubeswapAdapter.deployed();
    ubeswapAdapterAddress = ubeswapAdapter.address;

    let tx = await addressResolver.setContractAddress("UbeswapAdapter", ubeswapAdapterAddress);
    await tx.wait();
  });

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    mobiusAdapter = await MobiusAdapterFactory.deploy(addressResolverAddress);
    await mobiusAdapter.deployed();
    mobiusAdapterAddress = mobiusAdapter.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    mobiusSwap = await MobiusSwapFactory.deploy();
    await mobiusSwap.deployed();
    mobiusSwapAddress = mobiusSwap.address;

    mobiusMasterMind = await MobiusMasterMindFactory.deploy();
    await mobiusMasterMind.deployed();
    mobiusMasterMindAddress = mobiusMasterMind.address;

    let tx = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("MobiusMasterMind", mobiusMasterMindAddress);
    await tx2.wait();

    let tx3 = await assetHandler.addAssetType(3, deployer.address);
    await tx3.wait();
  });

  describe("#addMobiusAsset", () => {
    it("only owner", async () => {
        let tx = mobiusAdapter.connect(otherUser).addMobiusAsset(mobiusTokenAddress, stakingTokenAddress, underlyingTokenAddress, mobiusSwapAddress, 1);
        await expect(tx).to.be.reverted;
    });

    it("denomination asset not valid", async () => {
        let tx = mobiusAdapter.addMobiusAsset(mobiusTokenAddress, stakingTokenAddress, underlyingTokenAddress, mobiusSwapAddress, 1);
        await expect(tx).to.be.reverted;
    });

    it("interest bearing token not valid", async () => {
        let tx = await assetHandler.addCurrencyKey(3, underlyingTokenAddress);
        await tx.wait();

        let tx2 = mobiusAdapter.addMobiusAsset(mobiusTokenAddress, stakingTokenAddress, underlyingTokenAddress, mobiusSwapAddress, 1);
        await expect(tx2).to.be.reverted;
    });

    it("meets requirements", async () => {
        let tx = await assetHandler.addCurrencyKey(3, underlyingTokenAddress);
        await tx.wait();

        let tx2 = await assetHandler.addCurrencyKey(3, mobiusTokenAddress);
        await tx2.wait();

        let tx3 = await mobiusAdapter.addMobiusAsset(mobiusTokenAddress, stakingTokenAddress, underlyingTokenAddress, mobiusSwapAddress, 1);
        await tx3.wait();

        let tx4 = await mobiusSwap.setLPToken(stakingTokenAddress);
        await tx4.wait();

        let tx5 = await mobiusMasterMind.setPendingNerve(1, deployer.address, parseEther("42"));
        await tx5.wait();

        let swap = await mobiusAdapter.getSwapAddress(stakingTokenAddress);
        expect(swap).to.equal(mobiusSwapAddress);

        let hasFarm = await mobiusAdapter.checkIfLPTokenHasFarm(stakingTokenAddress);
        expect(hasFarm).to.be.true;

        let pair1 = await mobiusAdapter.getPair(underlyingTokenAddress, mobiusTokenAddress);
        expect(pair1).to.equal(stakingTokenAddress);

        let pair2 = await mobiusAdapter.getPair(mobiusTokenAddress, underlyingTokenAddress);
        expect(pair2).to.equal(stakingTokenAddress);

        let pendingRewards = await mobiusAdapter.getAvailableRewards(deployer.address, 1);
        expect(pendingRewards).to.equal(parseEther("42"));
        
    });

    it("asset already exists", async () => {
        let tx = await assetHandler.addCurrencyKey(3, underlyingTokenAddress);
        await tx.wait();

        let tx2 = await assetHandler.addCurrencyKey(3, mobiusTokenAddress);
        await tx2.wait();

        let tx3 = await mobiusAdapter.addMobiusAsset(mobiusTokenAddress, stakingTokenAddress, underlyingTokenAddress, mobiusSwapAddress, 1);
        await tx3.wait();

        let tx4 = mobiusAdapter.addMobiusAsset(mobiusTokenAddress, stakingTokenAddress, underlyingTokenAddress, mobiusSwapAddress, 1);
        await expect(tx4).to.be.reverted;
    });
  });

  describe("#setEquivalentUbeswapAsset", () => {
    it("only owner", async () => {
        let tx = mobiusAdapter.connect(otherUser).setEquivalentUbeswapAsset(underlyingTokenAddress, otherUser.address);
        await expect(tx).to.be.reverted;
    });

    it("meets requirements", async () => {
        let tx = await mobiusAdapter.setEquivalentUbeswapAsset(underlyingTokenAddress, otherUser.address);
        await tx.wait();

        let equivalentAsset = await mobiusAdapter.equivalentUbeswapAsset(underlyingTokenAddress);
        expect(equivalentAsset).to.equal(otherUser.address);
    });
  });

  describe("#getPrice", () => {
    it("asset is not valid", async () => {
        let price = mobiusAdapter.getPrice(mobiusTokenAddress);
        await expect(price).to.be.reverted;
    });

    it("asset is denomination asset", async () => {
        let tx = await mobiusAdapter.setEquivalentUbeswapAsset(underlyingTokenAddress, otherUser.address);
        await tx.wait();

        let tx2 = await ubeswapAdapter.setPrice(otherUser.address, parseEther("2"));
        await tx2.wait();

        let price = await mobiusAdapter.getPrice(underlyingTokenAddress);
        expect(price).to.equal(parseEther("2"));
    });

    it("asset is mobius asset", async () => {
        let tx = await mobiusAdapter.setEquivalentUbeswapAsset(underlyingTokenAddress, otherUser.address);
        await tx.wait();

        let tx2 = await ubeswapAdapter.setPrice(otherUser.address, parseEther("2"));
        await tx2.wait();

        let tx3 = await mobiusSwap.setVirtualPrice(parseEther("5"));
        await tx3.wait();

        let price = await mobiusAdapter.getPrice(mobiusTokenAddress);
        expect(price).to.equal(parseEther("10"));
    });
  });

  describe("#getAvailableMobiusFarms", () => {
    it("no farms", async () => {
        let farms = await mobiusAdapter.getAvailableMobiusFarms();
        expect(farms[0].length).to.equal(0);
        expect(farms[1].length).to.equal(1);
    });

    it("one farm", async () => {
        let tx = await assetHandler.addCurrencyKey(3, underlyingTokenAddress);
        await tx.wait();

        let tx2 = await assetHandler.addCurrencyKey(3, mobiusTokenAddress);
        await tx2.wait();

        let tx3 = await mobiusAdapter.addMobiusAsset(mobiusTokenAddress, stakingTokenAddress, underlyingTokenAddress, mobiusSwapAddress, 1);
        await tx3.wait();

        let farms = await mobiusAdapter.getAvailableMobiusFarms();
        expect(farms[0].length).to.equal(1);
        expect(farms[1].length).to.equal(1);
        expect(farms[0][0]).to.equal(stakingTokenAddress);
        expect(farms[1][0]).to.equal(1);
    });

    it("multiple farms", async () => {
        let tx = await assetHandler.addCurrencyKey(3, underlyingTokenAddress);
        await tx.wait();

        let tx2 = await assetHandler.addCurrencyKey(3, mobiusTokenAddress);
        await tx2.wait();

        let tx3 = await mobiusAdapter.addMobiusAsset(mobiusTokenAddress, stakingTokenAddress, underlyingTokenAddress, mobiusSwapAddress, 1);
        await tx3.wait();

        let tx4 = await mobiusAdapter.addMobiusAsset(mobiusTokenAddress, otherUser.address, underlyingTokenAddress, mobiusSwapAddress, 2);
        await tx4.wait();

        let farms = await mobiusAdapter.getAvailableMobiusFarms();
        expect(farms[0].length).to.equal(2);
        expect(farms[1].length).to.equal(2);
        expect(farms[0][0]).to.equal(stakingTokenAddress);
        expect(farms[0][1]).to.equal(otherUser.address);
        expect(farms[1][0]).to.equal(1);
        expect(farms[1][1]).to.equal(2);
    });
  });
});