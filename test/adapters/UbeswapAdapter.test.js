const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("UbeswapAdapter", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let tradegenToken;
  let tradegenTokenAddress;
  let mockCELO;
  let mockCELOAddress;
  let mockUSDC;
  let mockUSDCAddress;
  let TestTokenFactory;

  let ubeswapPoolManager;
  let ubeswapPoolManagerAddress;
  let UbeswapPoolManagerFactory;

  let stakingRewards;
  let stakingRewardsAddress;
  let StakingRewardsFactory;

  let ubeswapPathManager;
  let ubeswapPathManagerAddress;
  let UbeswapPathManagerFactory;

  let ubeswapFactory;
  let ubeswapFactoryAddress;
  let UbeswapFactoryFactory;

  let ubeswapRouter;
  let ubeswapRouterAddress;
  let UbeswapRouterFactory;

  let ubeswapAdapter;
  let ubeswapAdapterAddress;
  let UbeswapAdapterFactory;
  
  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    UbeswapPoolManagerFactory = await ethers.getContractFactory('TestUbeswapPoolManager');
    StakingRewardsFactory = await ethers.getContractFactory('TestStakingRewards');
    TestTokenFactory = await ethers.getContractFactory('TestTokenERC20');
    UbeswapFactoryFactory = await ethers.getContractFactory('UniswapV2Factory');
    UbeswapRouterFactory = await ethers.getContractFactory('UniswapV2Router02');
    UbeswapPathManagerFactory = await ethers.getContractFactory('UbeswapPathManager');
    UbeswapAdapterFactory = await ethers.getContractFactory('UbeswapAdapter');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    tradegenToken = await TestTokenFactory.deploy("Test TGEN", "TGEN");
    await tradegenToken.deployed();
    tradegenTokenAddress = tradegenToken.address;

    mockCELO = await TestTokenFactory.deploy("Test CELO", "CELO");
    await mockCELO.deployed();
    mockCELOAddress = mockCELO.address;

    mockUSDC = await TestTokenFactory.deploy("Test USDC", "USDC");
    await mockUSDC.deployed();
    mockUSDCAddress = mockUSDC.address;

    ubeswapPoolManager = await UbeswapPoolManagerFactory.deploy();
    await ubeswapPoolManager.deployed();
    ubeswapPoolManagerAddress = ubeswapPoolManager.address;

    stakingRewards = await StakingRewardsFactory.deploy();
    await stakingRewards.deployed();
    stakingRewardsAddress = stakingRewards.address;

    let tx2 = await addressResolver.setContractAddress("UbeswapPoolManager", ubeswapPoolManagerAddress);
    await tx2.wait();
  });

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    otherUser = signers[1];

    ubeswapFactory = await UbeswapFactoryFactory.deploy(deployer.address);
    await ubeswapFactory.deployed();
    ubeswapFactoryAddress = ubeswapFactory.address;

    ubeswapRouter = await UbeswapRouterFactory.deploy(ubeswapFactoryAddress);
    await ubeswapRouter.deployed();
    ubeswapRouterAddress = ubeswapRouter.address;

    ubeswapAdapter = await UbeswapAdapterFactory.deploy(addressResolverAddress);
    await ubeswapAdapter.deployed();
    ubeswapAdapterAddress = ubeswapAdapter.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    ubeswapPathManager = await UbeswapPathManagerFactory.deploy(addressResolverAddress);
    await ubeswapPathManager.deployed();
    ubeswapPathManagerAddress = ubeswapPathManager.address;

    let tx = await addressResolver.setContractAddress("UbeswapPathManager", ubeswapPathManagerAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("UbeswapRouter", ubeswapRouterAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("UniswapV2Factory", ubeswapFactoryAddress);
    await tx3.wait();

    let tx4 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx4.wait();

    let tx5 = await tradegenToken.approve(ubeswapRouterAddress, parseEther("1500"));
    await tx5.wait();

    let tx6 = await mockCELO.approve(ubeswapRouterAddress, parseEther("2000"));
    await tx6.wait();

    let tx7 = await mockUSDC.approve(ubeswapRouterAddress, parseEther("1500"));
    await tx7.wait();

    // Create TGEN-CELO pair and supply seed liquidity.
    // Initial price of 1.
    let tx8 = await ubeswapRouter.addLiquidity(tradegenTokenAddress, mockCELOAddress, parseEther("1000"), parseEther("1000"), 0, 0, deployer.address, 999999999999999);
    await tx8.wait();

    // Create CELO-USDC pair and supply seed liquidity.
    // Initial price of 0.5.
    let tx9 = await ubeswapRouter.addLiquidity(mockCELOAddress, mockUSDCAddress, parseEther("1000"), parseEther("500"), 0, 0, deployer.address, 999999999999999);
    await tx9.wait();

    // Create TGEN-USDC pair and supply seed liquidity.
    // Initial price of 2.
    let tx10 = await ubeswapRouter.addLiquidity(tradegenTokenAddress, mockUSDCAddress, parseEther("500"), parseEther("1000"), 0, 0, deployer.address, 999999999999999);
    await tx10.wait();
  });
  
  describe("#getPrice", () => {
    it("not valid asset", async () => {
        let price = ubeswapAdapter.getPrice(tradegenTokenAddress);
        await expect(price).to.be.reverted;
    });

    it("no path for asset", async () => {
        let tx = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
        await tx.wait();

        let tx2 = await assetHandler.setStableCoinAddress(mockUSDCAddress);
        await tx2.wait();

        let price = ubeswapAdapter.getPrice(tradegenTokenAddress);
        await expect(price).to.be.reverted;
    });

    it("stablecoin", async () => {
        let tx = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
        await tx.wait();

        let tx2 = await assetHandler.setStableCoinAddress(mockUSDCAddress);
        await tx2.wait();

        let price = await ubeswapAdapter.getPrice(mockUSDCAddress);
        expect(price).to.equal(parseEther("1"));
    });

    it("price > 1", async () => {
        let tx = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
        await tx.wait();

        let tx2 = await assetHandler.setStableCoinAddress(mockUSDCAddress);
        await tx2.wait();

        let tx3 = await ubeswapPathManager.setPath(tradegenTokenAddress, mockUSDCAddress, [tradegenTokenAddress, mockUSDCAddress]);
        await tx3.wait();

        let price = await ubeswapAdapter.getPrice(tradegenTokenAddress);
        expect(price.toString()).to.equal("1990031876438381866");
    });

    it("price < 1", async () => {
        let tx = await assetHandler.setValidAsset(mockCELOAddress, 1);
        await tx.wait();

        let tx2 = await assetHandler.setStableCoinAddress(mockUSDCAddress);
        await tx2.wait();

        let tx3 = await ubeswapPathManager.setPath(mockCELOAddress, mockUSDCAddress, [mockCELOAddress, mockUSDCAddress]);
        await tx3.wait();

        let price = await ubeswapAdapter.getPrice(mockCELOAddress);
        expect(price.toString()).to.equal("498003490519951608");
    });
  });

  describe("#getAmountsOut", () => {
    it("not valid asset", async () => {
        let amount = ubeswapAdapter.getAmountsOut(parseEther("1"), tradegenTokenAddress, mockUSDCAddress);
        await expect(amount).to.be.reverted;
    });

    it("no path for asset", async () => {
        let tx = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
        await tx.wait();

        let tx2 = await assetHandler.setStableCoinAddress(mockUSDCAddress);
        await tx2.wait();

        let amount = ubeswapAdapter.getAmountsOut(parseEther("1"), tradegenTokenAddress, mockUSDCAddress);
        await expect(amount).to.be.reverted;
    });

    it("meets requirements", async () => {
        let tx = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
        await tx.wait();

        let tx2 = await assetHandler.setStableCoinAddress(mockUSDCAddress);
        await tx2.wait();

        let tx3 = await ubeswapPathManager.setPath(tradegenTokenAddress, mockUSDCAddress, [tradegenTokenAddress, mockUSDCAddress]);
        await tx3.wait();

        let amount = await ubeswapAdapter.getAmountsOut(parseEther("1"), tradegenTokenAddress, mockUSDCAddress);
        expect(amount.toString()).to.equal("1990031876438381866");
    });
  });

  describe("#getAmountsIn", () => {
    it("not valid asset", async () => {
        let amount = ubeswapAdapter.getAmountsIn(parseEther("1"), tradegenTokenAddress, mockUSDCAddress);
        await expect(amount).to.be.reverted;
    });

    it("no path for asset", async () => {
        let tx = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
        await tx.wait();

        let tx2 = await assetHandler.setStableCoinAddress(mockUSDCAddress);
        await tx2.wait();

        let amount = ubeswapAdapter.getAmountsIn(parseEther("1"), tradegenTokenAddress, mockUSDCAddress);
        await expect(amount).to.be.reverted;
    });

    it("meets requirements", async () => {
        let tx = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
        await tx.wait();

        let tx2 = await assetHandler.setStableCoinAddress(mockUSDCAddress);
        await tx2.wait();

        let tx3 = await ubeswapPathManager.setPath(tradegenTokenAddress, mockUSDCAddress, [tradegenTokenAddress, mockUSDCAddress]);
        await tx3.wait();

        let amount = await ubeswapAdapter.getAmountsIn(parseEther("1"), tradegenTokenAddress, mockUSDCAddress);
        expect(amount.toString()).to.equal("502006520060682549");
    });
  });

  describe("#getAvailableUbeswapFarms", () => {
    it("no farms", async () => {
        let farms = await ubeswapAdapter.getAvailableUbeswapFarms();
        expect(farms.length).to.equal(0);
    });

    it("several farms", async () => {
        let tx = await ubeswapPoolManager.setPoolsCount(3);
        await tx.wait();

        let tx2 = await ubeswapPoolManager.setPoolsByIndex(0, tradegenTokenAddress);
        await tx2.wait();

        let tx3 = await ubeswapPoolManager.setPoolsByIndex(1, mockCELOAddress);
        await tx3.wait();

        let tx4 = await ubeswapPoolManager.setPoolsByIndex(2, mockUSDCAddress);
        await tx4.wait();

        let tx5 = await ubeswapPoolManager.setPools(0, tradegenTokenAddress, tradegenTokenAddress, 1, 1);
        await tx5.wait();

        let tx6 = await ubeswapPoolManager.setPools(1, mockCELOAddress, mockCELOAddress, 1, 1);
        await tx6.wait();

        let tx7 = await ubeswapPoolManager.setPools(2, mockUSDCAddress, mockUSDCAddress, 1, 1);
        await tx7.wait();

        let farms = await ubeswapAdapter.getAvailableUbeswapFarms();
        expect(farms.length).to.equal(3);
        expect(farms[0]).to.equal(tradegenTokenAddress);
        expect(farms[1]).to.equal(mockCELOAddress);
        expect(farms[2]).to.equal(mockUSDCAddress);
    });
  });
});*/