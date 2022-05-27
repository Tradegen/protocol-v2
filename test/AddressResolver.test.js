const { expect } = require("chai");

describe("AddressResolver", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
  });

  beforeEach(async () => {
    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;
  });

  describe("#setContractAddress", () => {
    it("onlyOwner", async () => {
        let tx = addressResolver.connect(otherUser).setContractAddress("Settings", otherUser.address);
        await expect(tx).to.be.reverted;
    });
    
    it("set contract address", async () => {
        let tx = await addressResolver.setContractAddress("Settings", otherUser.address);
        await tx.wait();

        const address = await addressResolver.getContractAddress("Settings");
        expect(address).to.equal(otherUser.address);
    });
  });
  
  describe("#setContractVerifier", () => {
    it("onlyOwner", async () => {
        let tx = addressResolver.connect(otherUser).setContractVerifier(otherUser.address, otherUser.address);
        await expect(tx).to.be.reverted;
    });

    it("set contract verifier", async () => {
        let tx = addressResolver.setContractVerifier(otherUser.address, otherUser.address);
        await tx.wait();

        const address = await addressResolver.contractVerifiers(otherUser.address);
        expect(address).to.equal(otherUser.address);
    });
  });

  describe("#setAssetVerifier", () => {
    it("onlyOwner", async () => {
        let tx = addressResolver.connect(otherUser).setAssetVerifier(1, otherUser.address);
        await expect(tx).to.be.reverted;
    });

    it("set asset verifier", async () => {
        let tx = await addressResolver.setAssetVerifier(1, otherUser.address);
        await tx.wait();

        const address = await addressResolver.assetVerifiers(1);
        expect(address).to.equal(otherUser.address);
    });
  });

  describe("#addPoolAddress", () => {
    it("onlyPoolFactory", async () => {
        let tx = await addressResolver.setContractAddress("PoolFactory", otherUser.address);
        await tx.wait();

        let tx2 = addressResolver.addPoolAddress(otherUser.address);
        await expect(tx2).to.be.reverted;
    });

    it("add pool address", async () => {
        let tx = await addressResolver.setContractAddress("PoolFactory", deployer.address);
        await tx.wait();

        let tx2 = await addressResolver.addPoolAddress(otherUser.address);
        await tx2.wait();

        const valid = await addressResolver.checkIfPoolAddressIsValid(otherUser.address);
        expect(valid).to.be.true;
    });
  });
});