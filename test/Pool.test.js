const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("Pool", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let pool;
  let poolAddress;
  let PoolFactory;

  let poolManagerLogic;
  let poolManagerLogicAddress;
  let PoolManagerLogicFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let settings;
  let settingsAddress;
  let SettingsFactory;

  let stablecoin;
  let tradegenToken;
  let stablecoinAddress;
  let tradegenTokenAddress;
  let TokenFactory;

  let bytes;
  let bytesAddress;
  let BytesFactory;

  let ERC20Verifier;
  let ERC20VerifierAddress;
  let ERC20VerifierFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    BytesFactory = await ethers.getContractFactory('Bytes');
    bytes = await BytesFactory.deploy();
    await bytes.deployed();
    bytesAddress = bytes.address;

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    PoolManagerLogicFactory = await ethers.getContractFactory('PoolManagerLogic');
    SettingsFactory = await ethers.getContractFactory('Settings');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    PoolFactory = await ethers.getContractFactory('Pool');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier', {
        libraries: {
            Bytes: bytesAddress,
        },
      });

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    settings = await SettingsFactory.deploy();
    await settings.deployed();
    settingsAddress = settings.address;

    stablecoin = await TokenFactory.deploy("Stablecoin", "SGD");
    await stablecoin.deployed();
    stablecoinAddress = stablecoin.address;

    tradegenToken = await TokenFactory.deploy("Tradegen", "TGEN");
    await tradegenToken.deployed();
    tradegenTokenAddress = tradegenToken.address;

    poolManagerLogic = await PoolManagerLogicFactory.deploy(deployer.address, 1000, addressResolverAddress);
    await poolManagerLogic.deployed();
    poolManagerLogicAddress = poolManagerLogic.address;

    ERC20Verifier = await ERC20VerifierFactory.deploy(addressResolverAddress);
    await ERC20Verifier.deployed();
    ERC20VerifierAddress = ERC20Verifier.address;

    let tx = await addressResolver.setContractAddress("Settings", settingsAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("Registry", deployer.address);
    await tx3.wait();

    let tx4 = await assetHandler.setStableCoinAddress(stablecoinAddress);
    await tx4.wait();

    let tx5 = await settings.setParameterValue("MaximumNumberOfPositionsInPool", 3);
    await tx5.wait();

    let tx6 = await assetHandler.setValidAsset(stablecoinAddress, 1);
    await tx6.wait();

    let tx7 = await assetHandler.setValidAsset(tradegenTokenAddress, 1);
    await tx7.wait();

    let tx8 = await poolManagerLogic.addAvailableAsset(stablecoinAddress);
    await tx8.wait();

    let tx9 = await poolManagerLogic.addDepositAsset(stablecoinAddress);
    await tx9.wait();

    let tx10 = await poolManagerLogic.addAvailableAsset(tradegenTokenAddress);
    await tx10.wait();

    let tx11 = await poolManagerLogic.addDepositAsset(tradegenTokenAddress);
    await tx11.wait();

    let tx12 = await stablecoin.transfer(otherUser.address, parseEther("10000"));
    await tx12.wait();

    let tx13 = await tradegenToken.transfer(otherUser.address, parseEther("10000"));
    await tx13.wait();

    let tx14 = await assetHandler.setVerifier(stablecoinAddress, ERC20VerifierAddress);
    await tx14.wait();

    let tx15 = await assetHandler.setVerifier(tradegenTokenAddress, ERC20VerifierAddress);
    await tx15.wait();
  });

  beforeEach(async () => {
    pool = await PoolFactory.deploy("Pool", deployer.address, addressResolverAddress);
    await pool.deployed();
    poolAddress = pool.address;

    let tx = await pool.setPoolManagerLogic(poolManagerLogicAddress);
    await tx.wait();
  });
  
  describe("#deposit", () => {
    it("is not deposit asset", async () => {
        let tx = pool.deposit(otherUser.address, 100)
        await expect(tx).to.be.reverted;

        let balanceOf = await pool.balanceOf(deployer.address);
        expect(balanceOf).to.equal(0);
    });  

    it("meets requirements", async () => {
        let tx = await assetHandler.setBalance(stablecoinAddress, parseEther("100"));
        await tx.wait();

        let tx2 = await stablecoin.approve(poolAddress, parseEther("100"));
        await tx2.wait();

        let tx3 = await pool.deposit(stablecoinAddress, parseEther("100"));
        await tx3.wait();

        let balanceOf = await pool.balanceOf(deployer.address);
        expect(balanceOf).to.equal(parseEther("100"));

        let totalSupply = await pool.totalSupply();
        expect(totalSupply).to.equal(parseEther("100"));

        let userDeposits = await pool.userDeposits(deployer.address);
        expect(userDeposits).to.equal(parseEther("100"));

        let totalDeposits = await pool.totalDeposits();
        expect(totalDeposits).to.equal(parseEther("100"));

        let poolValue = await pool.getPoolValue();
        expect(poolValue).to.equal(parseEther("100"));

        let tokenPrice = await pool.tokenPrice();
        expect(tokenPrice).to.equal(parseEther("1"));

        let data = await pool.getPositionsAndTotal();
        expect(data[0].length).to.equal(2);
        expect(data[0][0]).to.equal(stablecoinAddress);
        expect(data[0][1]).to.equal(tradegenTokenAddress);
        expect(data[1].length).to.equal(2);
        expect(data[1][0]).to.equal(parseEther("100"));
        expect(data[1][1]).to.equal(0);
        expect(data[2]).to.equal(parseEther("100"));
    });
  });
  
  describe("#withdraw", () => {
    it("not enough balance", async () => {
        let tx = await assetHandler.setBalance(stablecoinAddress, parseEther("100"));
        await tx.wait();

        let tx2 = await stablecoin.approve(poolAddress, parseEther("100"));
        await tx2.wait();

        let tx3 = await pool.deposit(stablecoinAddress, parseEther("100"));
        await tx3.wait();

        let tx4 = pool.withdraw(parseEther("1000"))
        await expect(tx4).to.be.reverted;

        let balanceOf = await pool.balanceOf(deployer.address);
        expect(balanceOf).to.equal(parseEther("100"));
    });  

    it("meets requirements; partial", async () => {
        let tx = await assetHandler.setBalance(stablecoinAddress, parseEther("50"));
        await tx.wait();

        let tx2 = await stablecoin.approve(poolAddress, parseEther("100"));
        await tx2.wait();

        let tx3 = await pool.deposit(stablecoinAddress, parseEther("100"));
        await tx3.wait();

        let tx4 = await pool.withdraw(parseEther("50"));
        await tx4.wait();

        let balanceOf = await pool.balanceOf(deployer.address);
        expect(balanceOf).to.equal(parseEther("50"));

        let totalSupply = await pool.totalSupply();
        expect(totalSupply).to.equal(parseEther("50"));

        let userDeposits = await pool.userDeposits(deployer.address);
        expect(userDeposits).to.equal(parseEther("50"));

        let totalDeposits = await pool.totalDeposits();
        expect(totalDeposits).to.equal(parseEther("50"));

        let poolValue = await pool.getPoolValue();
        expect(poolValue).to.equal(parseEther("50"));

        let tokenPrice = await pool.tokenPrice();
        expect(tokenPrice).to.equal(parseEther("1"));

        let data = await pool.getPositionsAndTotal();
        expect(data[0].length).to.equal(2);
        expect(data[0][0]).to.equal(stablecoinAddress);
        expect(data[0][1]).to.equal(tradegenTokenAddress);
        expect(data[1].length).to.equal(2);
        expect(data[1][0]).to.equal(parseEther("50"));
        expect(data[1][1]).to.equal(0);
        expect(data[2]).to.equal(parseEther("50"));
    });

    it("meets requirements; all", async () => {
        let tx = await assetHandler.setBalance(stablecoinAddress, parseEther("100"));
        await tx.wait();

        let tx2 = await stablecoin.approve(poolAddress, parseEther("100"));
        await tx2.wait();

        let tx3 = await pool.deposit(stablecoinAddress, parseEther("100"));
        await tx3.wait();

        let tx4 = await pool.withdraw(parseEther("100"));
        await tx4.wait();

        let tx5 = await assetHandler.setBalance(stablecoinAddress, 0);
        await tx5.wait();
        
        let balanceOf = await pool.balanceOf(deployer.address);
        expect(balanceOf).to.equal(0);

        let totalSupply = await pool.totalSupply();
        expect(totalSupply).to.equal(0);

        let userDeposits = await pool.userDeposits(deployer.address);
        expect(userDeposits).to.equal(0);

        let totalDeposits = await pool.totalDeposits();
        expect(totalDeposits).to.equal(0);

        let poolValue = await pool.getPoolValue();
        expect(poolValue).to.equal(0);

        let tokenPrice = await pool.tokenPrice();
        expect(tokenPrice).to.equal(parseEther("1"));

        let data = await pool.getPositionsAndTotal();
        expect(data[0].length).to.equal(2);
        expect(data[0][0]).to.equal(stablecoinAddress);
        expect(data[0][1]).to.equal(tradegenTokenAddress);
        expect(data[1].length).to.equal(2);
        expect(data[1][0]).to.equal(0);
        expect(data[1][1]).to.equal(0);
        expect(data[2]).to.equal(0);
    });

    it("meets requirements; withdraw all and deposit again", async () => {
        let tx = await assetHandler.setBalance(stablecoinAddress, parseEther("50"));
        await tx.wait();

        let tx2 = await stablecoin.approve(poolAddress, parseEther("100"));
        await tx2.wait();

        let tx3 = await pool.deposit(stablecoinAddress, parseEther("100"));
        await tx3.wait();

        let tx4 = await pool.withdraw(parseEther("100"));
        await tx4.wait();

        let tx5 = await stablecoin.approve(poolAddress, parseEther("50"));
        await tx5.wait();

        let tx6 = await pool.deposit(stablecoinAddress, parseEther("50"));
        await tx6.wait();

        let balanceOf = await pool.balanceOf(deployer.address);
        expect(balanceOf).to.equal(parseEther("50"));

        let totalSupply = await pool.totalSupply();
        expect(totalSupply).to.equal(parseEther("50"));

        let userDeposits = await pool.userDeposits(deployer.address);
        expect(userDeposits).to.equal(parseEther("50"));

        let totalDeposits = await pool.totalDeposits();
        expect(totalDeposits).to.equal(parseEther("50"));

        let poolValue = await pool.getPoolValue();
        expect(poolValue).to.equal(parseEther("50"));

        let tokenPrice = await pool.tokenPrice();
        expect(tokenPrice).to.equal(parseEther("1"));

        let data = await pool.getPositionsAndTotal();
        expect(data[0].length).to.equal(2);
        expect(data[0][0]).to.equal(stablecoinAddress);
        expect(data[0][1]).to.equal(tradegenTokenAddress);
        expect(data[1].length).to.equal(2);
        expect(data[1][0]).to.equal(parseEther("50"));
        expect(data[1][1]).to.equal(0);
        expect(data[2]).to.equal(parseEther("50"));
    });
  });
});