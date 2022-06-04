const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("CappedPoolFactory", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let cappedPool;
  let cappedPoolAddress;
  let CappedPoolFactory;

  let cappedPoolFactoryContract;
  let cappedPoolFactoryAddress;
  let CappedPoolFactoryFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    CappedPoolFactory = await ethers.getContractFactory('CappedPool');
    CappedPoolFactoryFactory = await ethers.getContractFactory('CappedPoolFactory');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    let tx = await addressResolver.setContractAddress("PoolManager", addressResolverAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("Registry", deployer.address);
    await tx2.wait();
  });

  beforeEach(async () => {
    cappedPoolFactoryContract = await CappedPoolFactoryFactory.deploy(addressResolverAddress);
    await cappedPoolFactoryContract.deployed();
    cappedPoolFactoryAddress = cappedPoolFactoryContract.address;

    let tx = await addressResolver.setContractAddress("CappedPoolFactory", cappedPoolFactoryAddress);
    await tx.wait();
  });
  
  describe("#createCappedPool", () => {
    it("onlyRegistry", async () => {
      let tx = cappedPoolFactoryContract.connect(otherUser).createCappedPool(deployer.address, "Test", 10000, parseEther("1"));
      await expect(tx).to.be.reverted;
    });

    it('meets requirements', async () => {
        let tx = await cappedPoolFactoryContract.createCappedPool(deployer.address, "Test", 10000, parseEther("1"));
        await tx.wait();
    });
  });
});*/