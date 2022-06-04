const { expect } = require("chai");
/*
describe("Settings", () => {
  let deployer;
  let otherUser;

  let settings;
  let settingsAddress;
  let SettingsFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    SettingsFactory = await ethers.getContractFactory('Settings');
  });

  beforeEach(async () => {
    settings = await SettingsFactory.deploy();
    await settings.deployed();
    settingsAddress = settings.address;
  });

  describe("#setParameterValue", () => {
    it("onlyOwner", async () => {
        let tx = settings.connect(otherUser).setParameterValue("TransactionFee", 30);
        await expect(tx).to.be.reverted;
    });

    it("set parameter value; no existing parameters", async () => {
        let tx = await settings.setParameterValue("TransactionFee", 30);
        await tx.wait();

        const value = await settings.getParameterValue("TransactionFee");
        expect(value).to.equal(30);
    });

    it("set parameter value; update same value multiple times", async () => {
      let tx = await settings.setParameterValue("TransactionFee", 30);
      await tx.wait();

      let tx2 = await settings.setParameterValue("TransactionFee", 40);
      expect(tx2).to.emit(settings, "SetParameterValue");
      await tx2.wait();

      const value = await settings.getParameterValue("TransactionFee");
      expect(value).to.equal(40);
    });
  });
});*/