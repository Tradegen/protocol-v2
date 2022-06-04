const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
/*
describe("CappedPoolNFTFactory", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let cappedPoolNFT;
  let cappedPoolNFTAddress;
  let CappedPoolNFTFactory;

  let cappedPoolNFTFactoryContract;
  let cappedPoolNFTFactoryAddress;
  let CappedPoolNFTFactoryFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    CappedPoolNFTFactory = await ethers.getContractFactory('CappedPoolNFT');
    CappedPoolNFTFactoryFactory = await ethers.getContractFactory('CappedPoolNFTFactory');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    let tx = await addressResolver.setContractAddress("Registry", deployer.address);
    await tx.wait();
  });

  beforeEach(async () => {
    cappedPoolNFTFactoryContract = await CappedPoolNFTFactoryFactory.deploy(addressResolverAddress);
    await cappedPoolNFTFactoryContract.deployed();
    cappedPoolNFTFactoryAddress = cappedPoolNFTFactoryContract.address;
  });
  
  describe("#createCappedPoolNFT", () => {
    it("onlyRegistry", async () => {
      let tx = cappedPoolNFTFactoryContract.connect(otherUser).createCappedPoolNFT(deployer.address, 10000);
      await expect(tx).to.be.reverted;
    });

    it('meets requirements', async () => {
        let tx = await cappedPoolNFTFactoryContract.createCappedPoolNFT(deployer.address, 10000);
        let temp = await tx.wait();
        let event = temp.events[temp.events.length - 1];
        cappedPoolNFTAddress = event.args.cappedPoolNFT;
        cappedPoolNFT = CappedPoolNFTFactory.attach(cappedPoolNFTAddress);
        
        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(500);
        expect(availableTokensByClass[1]).to.equal(1000);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);
    });
  });
});*/