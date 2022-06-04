const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("PoolFactory", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let poolFactoryContract;
  let poolFactoryAddress;
  let PoolFactoryFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    PoolFactoryFactory = await ethers.getContractFactory('PoolFactory');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    let tx = await addressResolver.setContractAddress("Registry", deployer.address);
    await tx.wait();
  });

  beforeEach(async () => {
    poolFactoryContract = await PoolFactoryFactory.deploy(addressResolverAddress);
    await poolFactoryContract.deployed();
    poolFactoryAddress = poolFactoryContract.address;

    let tx = await addressResolver.setContractAddress("PoolFactory", poolFactoryAddress);
    await tx.wait();
  });
  
  describe("#createPool", () => {
    it("onlyRegistry", async () => {
      let tx = poolFactoryContract.connect(otherUser).createPool("Pool");
      await expect(tx).to.be.reverted;
    });

    it('meets requirements', async () => {
        let tx = await poolFactoryContract.createPool("Pool");
        await tx.wait();
    });
  });
});*/