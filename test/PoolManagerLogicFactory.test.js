const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("CappedPoolNFTFactory", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let poolManagerLogic;
  let poolManagerLogicAddress;
  let PoolManagerLogicFactory;

  let poolManagerLogicFactoryContract;
  let poolManagerLogicFactoryAddress;
  let PoolManagerLogicFactoryFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    PoolManagerLogicFactory = await ethers.getContractFactory('PoolManagerLogic');
    PoolManagerLogicFactoryFactory = await ethers.getContractFactory('PoolManagerLogicFactory');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    let tx = await addressResolver.setContractAddress("Registry", deployer.address);
    await tx.wait();
  });

  beforeEach(async () => {
    poolManagerLogicFactoryContract = await PoolManagerLogicFactoryFactory.deploy(addressResolverAddress);
    await poolManagerLogicFactoryContract.deployed();
    poolManagerLogicFactoryAddress = poolManagerLogicFactoryContract.address;
  });
  
  describe("#createPoolManagerLogic", () => {
    it("onlyRegistry", async () => {
      let tx = poolManagerLogicFactoryContract.connect(otherUser).createPoolManagerLogic(deployer.address, otherUser.address, 1000);
      await expect(tx).to.be.reverted;
    });

    it('meets requirements', async () => {
        let tx = await poolManagerLogicFactoryContract.createPoolManagerLogic(deployer.address, otherUser.address, 1000);
        let temp = await tx.wait();
        let event = temp.events[temp.events.length - 1];
        poolManagerLogicAddress = event.args.poolManagerLogicAddress;
        poolManagerLogic = PoolManagerLogicFactory.attach(poolManagerLogicAddress);
        
        let manager = await poolManagerLogic.manager();
        expect(manager).to.equal(otherUser.address);

        let performanceFee = await poolManagerLogic.performanceFee();
        expect(performanceFee).to.equal(1000);
    });
  });
});