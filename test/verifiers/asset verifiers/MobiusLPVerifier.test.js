const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("MobiusLPVerifier", () => {
  let deployer;
  let otherUser;

  let bytes;
  let bytesAddress;
  let BytesFactory;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let rewardToken;
  let rewardTokenAddress;
  let TokenFactory;

  let mobiusLPVerifier;
  let mobiusLPVerifierAddress;
  let MobiusLPVerifierFactory;

  let mobiusMastermind;
  let mobiusMastermindAddress;
  let MobiusMastermindFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    BytesFactory = await ethers.getContractFactory('Bytes');
    bytes = await BytesFactory.deploy();
    await bytes.deployed();
    bytesAddress = bytes.address;

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    MobiusMastermindFactory = await ethers.getContractFactory('TestMobiusMastermind');
    MobiusLPVerifierFactory = await ethers.getContractFactory('MobiusLPVerifier', {
        libraries: {
            Bytes: bytesAddress,
        },
    });

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    rewardToken = await TokenFactory.deploy("Reward Token", "RWD");
    await rewardToken.deployed();
    rewardTokenAddress = rewardToken.address;

    mobiusMastermind = await MobiusMastermindFactory.deploy();
    await mobiusMastermind.deployed();
    mobiusMastermindAddress = mobiusMastermind.address;
  });

  beforeEach(async () => {
    mobiusLPVerifier = await MobiusLPVerifierFactory.deploy(addressResolverAddress, mobiusMastermindAddress, rewardTokenAddress);
    await mobiusLPVerifier.deployed();
    mobiusLPVerifierAddress = mobiusLPVerifier.address;
  });

  describe("#setFarmAddress", () => {
    it("only owner", async () => {
        let tx = mobiusLPVerifier.connect(otherUser).setFarmAddress(rewardTokenAddress, 1);
        await expect(tx).to.be.reverted;
    });

    it("meets requirements", async () => {
        let tx = await mobiusLPVerifier.setFarmAddress(rewardTokenAddress, 1);
        await tx.wait();

        let mobiusFarm = await mobiusLPVerifier.mobiusFarms(1);
        expect(mobiusFarm).to.equal(rewardTokenAddress);

        let stakingToken = await mobiusLPVerifier.stakingTokens(rewardTokenAddress);
        expect(stakingToken).to.equal(1);
    });

    it("farm already exists", async () => {
        let tx = await mobiusLPVerifier.setFarmAddress(rewardTokenAddress, 1);
        await tx.wait();

        let tx2 = mobiusLPVerifier.setFarmAddress(otherUser.address, 1);
        await expect(tx2).to.be.reverted;

        let mobiusFarm = await mobiusLPVerifier.mobiusFarms(1);
        expect(mobiusFarm).to.equal(rewardTokenAddress);

        let stakingToken = await mobiusLPVerifier.stakingTokens(rewardTokenAddress);
        expect(stakingToken).to.equal(1);
    });
  });
  
  describe("#getFarm", () => {
    it("get Ubeswap farm", async () => {
        let tx = await mobiusLPVerifier.setFarmAddress(rewardTokenAddress, 1);
        await tx.wait();

        const farm = await mobiusLPVerifier.getFarmID(rewardTokenAddress);
        expect(farm[0]).to.equal(1);
        expect(farm[1]).to.equal(rewardTokenAddress);
    });
  });
  
  describe("#getBalance", () => {
    it("get balance", async () => {
        let tx = await mobiusLPVerifier.setFarmAddress(rewardTokenAddress, 1);
        await tx.wait();

        let tx2 = await mobiusMastermind.setAmount(parseEther("88"));
        await tx2.wait();

        let tx3 = await rewardToken.transfer(otherUser.address, parseEther("10"));
        await tx3.wait();

        const value = await mobiusLPVerifier.getBalance(otherUser.address, rewardTokenAddress);
        expect(value).to.equal(parseEther("98"));
    });
  });
  
  describe("#prepareWithdrawal", () => {
    it("prepare withdrawal", async () => {
        let tx = await mobiusLPVerifier.setFarmAddress(rewardTokenAddress, 1);
        await tx.wait();

        let tx2 = await mobiusMastermind.setAmount(parseEther("10"));
        await tx2.wait();

        const data = await mobiusLPVerifier.prepareWithdrawal(otherUser.address, rewardTokenAddress, parseEther("1"));
        
        expect(data[0]).to.equal(rewardTokenAddress);
        expect(data[1]).to.equal(parseEther("10"));
        expect(data[2].length).to.equal(1);
        expect(data[3].length).to.equal(1);
    });
  });
});*/