const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");

describe("CappedPoolNFT", () => {
  let deployer;
  let otherUser;

  let cappedPool;
  let cappedPoolAddress;
  let CappedPoolFactory;

  let cappedPoolNFT;
  let cappedPoolNFTAddress;
  let CappedPoolNFTFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    CappedPoolFactory = await ethers.getContractFactory('TestCappedPool');
    CappedPoolNFTFactory = await ethers.getContractFactory('CappedPoolNFT');

    cappedPool = await CappedPoolFactory.deploy();
    await cappedPool.deployed();
    cappedPoolAddress = cappedPool.address;
  });

  beforeEach(async () => {
    cappedPoolNFT = await CappedPoolNFTFactory.deploy(cappedPoolAddress, 10000);
    await cappedPoolNFT.deployed();
    cappedPoolNFTAddress = cappedPoolNFT.address;

    let tx = await cappedPool.setNFT(cappedPoolNFTAddress);
    await tx.wait();
  });
  
  describe("#depositByClass", () => {
    it("not pool", async () => {
        let tx = cappedPoolNFT.connect(otherUser).depositByClass(deployer.address, 100, parseEther("1"));
        await expect(tx).to.be.reverted;

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(0);
    });

    it('no existing tokens; 1 class', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 100, parseEther("1"));
        await tx.wait();

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(100);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(100);

        let userDeposit = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDeposit).to.equal(parseEther("1"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("1"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(400);
        expect(availableTokensByClass[1]).to.equal(1000);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOf = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf).to.equal(100);
    });

    it('no existing tokens; 2 classes', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 1000, parseEther("1"));
        await tx.wait();

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(1000);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(1000);

        let userDeposit = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDeposit).to.equal(parseEther("1"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("1"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(0);
        expect(availableTokensByClass[1]).to.equal(500);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOf1 = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf1).to.equal(500);

        let balanceOf2 = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOf2).to.equal(500);
    });

    it('no existing tokens; 3 classes', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 2000, parseEther("1"));
        await tx.wait();

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(2000);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(2000);

        let userDeposit = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDeposit).to.equal(parseEther("1"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("1"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(0);
        expect(availableTokensByClass[1]).to.equal(0);
        expect(availableTokensByClass[2]).to.equal(1500);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOf1 = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf1).to.equal(500);

        let balanceOf2 = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOf2).to.equal(1000);

        let balanceOf3 = await cappedPoolNFT.balanceOf(deployer.address, 3);
        expect(balanceOf3).to.equal(500);
    });

    it('no existing tokens; 4 classes', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 5000, parseEther("1"));
        await tx.wait();

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(5000);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(5000);

        let userDeposit = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDeposit).to.equal(parseEther("1"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("1"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(0);
        expect(availableTokensByClass[1]).to.equal(0);
        expect(availableTokensByClass[2]).to.equal(0);
        expect(availableTokensByClass[3]).to.equal(5000);

        let balanceOf1 = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf1).to.equal(500);

        let balanceOf2 = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOf2).to.equal(1000);

        let balanceOf3 = await cappedPoolNFT.balanceOf(deployer.address, 3);
        expect(balanceOf3).to.equal(2000);

        let balanceOf4 = await cappedPoolNFT.balanceOf(deployer.address, 4);
        expect(balanceOf4).to.equal(1500);
    });

    it('existing tokens; some C1', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 100, parseEther("1"));
        await tx.wait();

        let tx2 = await cappedPool.depositByClass(otherUser.address, 300, parseEther("5"));
        await tx2.wait();

        let balanceDeployer = await cappedPoolNFT.balance(deployer.address);
        expect(balanceDeployer).to.equal(100);

        let balanceOther = await cappedPoolNFT.balance(otherUser.address);
        expect(balanceOther).to.equal(300);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(400);

        let userDepositDeployer = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDepositDeployer).to.equal(parseEther("1"));

        let userDepositOther = await cappedPoolNFT.userDeposits(otherUser.address);
        expect(userDepositOther).to.equal(parseEther("5"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("6"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(100);
        expect(availableTokensByClass[1]).to.equal(1000);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOf1Deployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf1Deployer).to.equal(100);

        let balanceOf1Other = await cappedPoolNFT.balanceOf(otherUser.address, 1);
        expect(balanceOf1Other).to.equal(300);
    });

    it('existing tokens; some C1 and C2', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 600, parseEther("1"));
        await tx.wait();

        let tx2 = await cappedPool.depositByClass(otherUser.address, 300, parseEther("5"));
        await tx2.wait();

        let balanceDeployer = await cappedPoolNFT.balance(deployer.address);
        expect(balanceDeployer).to.equal(600);

        let balanceOther = await cappedPoolNFT.balance(otherUser.address);
        expect(balanceOther).to.equal(300);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(900);

        let userDepositDeployer = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDepositDeployer).to.equal(parseEther("1"));

        let userDepositOther = await cappedPoolNFT.userDeposits(otherUser.address);
        expect(userDepositOther).to.equal(parseEther("5"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("6"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(0);
        expect(availableTokensByClass[1]).to.equal(600);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOf1Deployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf1Deployer).to.equal(500);

        let balanceOf1Other = await cappedPoolNFT.balanceOf(otherUser.address, 1);
        expect(balanceOf1Other).to.equal(0);

        let balanceOf2Deployer = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOf2Deployer).to.equal(100);

        let balanceOf2Other = await cappedPoolNFT.balanceOf(otherUser.address, 2);
        expect(balanceOf2Other).to.equal(300);
    });

    it('existing tokens; some C1, C2, and C3', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 1600, parseEther("1"));
        await tx.wait();

        let tx2 = await cappedPool.depositByClass(otherUser.address, 300, parseEther("5"));
        await tx2.wait();

        let balanceDeployer = await cappedPoolNFT.balance(deployer.address);
        expect(balanceDeployer).to.equal(1600);

        let balanceOther = await cappedPoolNFT.balance(otherUser.address);
        expect(balanceOther).to.equal(300);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(1900);

        let userDepositDeployer = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDepositDeployer).to.equal(parseEther("1"));

        let userDepositOther = await cappedPoolNFT.userDeposits(otherUser.address);
        expect(userDepositOther).to.equal(parseEther("5"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("6"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(0);
        expect(availableTokensByClass[1]).to.equal(0);
        expect(availableTokensByClass[2]).to.equal(1600);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOf1Deployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf1Deployer).to.equal(500);

        let balanceOf1Other = await cappedPoolNFT.balanceOf(otherUser.address, 1);
        expect(balanceOf1Other).to.equal(0);

        let balanceOf2Deployer = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOf2Deployer).to.equal(1000);

        let balanceOf2Other = await cappedPoolNFT.balanceOf(otherUser.address, 2);
        expect(balanceOf2Other).to.equal(0);

        let balanceOf3Deployer = await cappedPoolNFT.balanceOf(deployer.address, 3);
        expect(balanceOf3Deployer).to.equal(100);

        let balanceOf3Other = await cappedPoolNFT.balanceOf(otherUser.address, 3);
        expect(balanceOf3Other).to.equal(300);
    });

    it('existing tokens; some of each class', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 4600, parseEther("1"));
        await tx.wait();

        let tx2 = await cappedPool.depositByClass(otherUser.address, 400, parseEther("5"));
        await tx2.wait();

        let balanceDeployer = await cappedPoolNFT.balance(deployer.address);
        expect(balanceDeployer).to.equal(4600);

        let balanceOther = await cappedPoolNFT.balance(otherUser.address);
        expect(balanceOther).to.equal(400);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(5000);

        let userDepositDeployer = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDepositDeployer).to.equal(parseEther("1"));

        let userDepositOther = await cappedPoolNFT.userDeposits(otherUser.address);
        expect(userDepositOther).to.equal(parseEther("5"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("6"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(0);
        expect(availableTokensByClass[1]).to.equal(0);
        expect(availableTokensByClass[2]).to.equal(0);
        expect(availableTokensByClass[3]).to.equal(5000);

        let balanceOf1Deployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf1Deployer).to.equal(500);

        let balanceOf1Other = await cappedPoolNFT.balanceOf(otherUser.address, 1);
        expect(balanceOf1Other).to.equal(0);

        let balanceOf2Deployer = await cappedPoolNFT.balanceOf(deployer.address, 2);
        expect(balanceOf2Deployer).to.equal(1000);

        let balanceOf2Other = await cappedPoolNFT.balanceOf(otherUser.address, 2);
        expect(balanceOf2Other).to.equal(0);

        let balanceOf3Deployer = await cappedPoolNFT.balanceOf(deployer.address, 3);
        expect(balanceOf3Deployer).to.equal(2000);

        let balanceOf3Other = await cappedPoolNFT.balanceOf(otherUser.address, 3);
        expect(balanceOf3Other).to.equal(0);

        let balanceOf4Deployer = await cappedPoolNFT.balanceOf(deployer.address, 4);
        expect(balanceOf4Deployer).to.equal(1100);

        let balanceOf4Other = await cappedPoolNFT.balanceOf(otherUser.address, 4);
        expect(balanceOf4Other).to.equal(400);
    });
  });

  describe("#burnTokens", () => {
    it("not pool", async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 100, parseEther("1"));
        await tx.wait();

        let tx2 = cappedPoolNFT.connect(otherUser).burnTokens(deployer.address, 1, 100);
        await expect(tx2).to.be.reverted;

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(100);
    });

    it('some tokens', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 100, parseEther("1"));
        await tx.wait();

        let tx2 = await cappedPool.burnTokens(deployer.address, 1, 50);
        await tx2.wait();

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(50);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(50);

        let userDeposit = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDeposit).to.equal(parseEther("0.5"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("0.5"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(450);
        expect(availableTokensByClass[1]).to.equal(1000);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOf = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf).to.equal(50);
    });

    it('all tokens', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 100, parseEther("1"));
        await tx.wait();

        let tx2 = await cappedPool.burnTokens(deployer.address, 1, 100);
        await tx2.wait();

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(0);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(0);

        let userDeposit = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDeposit).to.equal(0);

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(0);

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(500);
        expect(availableTokensByClass[1]).to.equal(1000);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOf = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf).to.equal(0);
    });

    it('burn tokens and deposit again', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 100, parseEther("1"));
        await tx.wait();

        let tx2 = await cappedPool.burnTokens(deployer.address, 1, 100);
        await tx2.wait();

        let tx3 = await cappedPool.depositByClass(deployer.address, 200, parseEther("100"));
        await tx3.wait();

        let balance = await cappedPoolNFT.balance(deployer.address);
        expect(balance).to.equal(200);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(200);

        let userDeposit = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDeposit).to.equal(parseEther("100"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("100"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(300);
        expect(availableTokensByClass[1]).to.equal(1000);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOf = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOf).to.equal(200);
    });
  });

  describe("#safeTransferFrom", () => {
    it('recipient has no tokens', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 100, parseEther("100"));
        await tx.wait();

        let tx2 = await cappedPoolNFT.setApprovalForAll(otherUser.address, true);
        await tx2.wait();

        let tx3 = await cappedPoolNFT.safeTransferFrom(deployer.address, otherUser.address, 1, 60, "0x00");
        await tx3.wait();

        let balanceDeployer = await cappedPoolNFT.balance(deployer.address);
        expect(balanceDeployer).to.equal(40);

        let balanceOther = await cappedPoolNFT.balance(otherUser.address);
        expect(balanceOther).to.equal(60);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(100);

        let userDepositDeployer = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDepositDeployer).to.equal(parseEther("40"));

        let userDepositOther = await cappedPoolNFT.userDeposits(otherUser.address);
        expect(userDepositOther).to.equal(parseEther("120"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("160"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(400);
        expect(availableTokensByClass[1]).to.equal(1000);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(40);

        let balanceOfOther = await cappedPoolNFT.balanceOf(otherUser.address, 1);
        expect(balanceOfOther).to.equal(60);
    });

    it('recipient has tokens', async () => {
        let tx = await cappedPool.depositByClass(deployer.address, 100, parseEther("100"));
        await tx.wait();

        let tx2 = await cappedPool.depositByClass(otherUser.address, 100, parseEther("200"));
        await tx2.wait();

        let tx3 = await cappedPoolNFT.setApprovalForAll(otherUser.address, true);
        await tx3.wait();

        let tx4 = await cappedPoolNFT.safeTransferFrom(deployer.address, otherUser.address, 1, 60, "0x00");
        await tx4.wait();

        let balanceDeployer = await cappedPoolNFT.balance(deployer.address);
        expect(balanceDeployer).to.equal(40);

        let balanceOther = await cappedPoolNFT.balance(otherUser.address);
        expect(balanceOther).to.equal(160);

        let totalSupply = await cappedPoolNFT.totalSupply();
        expect(totalSupply).to.equal(200);

        let userDepositDeployer = await cappedPoolNFT.userDeposits(deployer.address);
        expect(userDepositDeployer).to.equal(parseEther("40"));

        let userDepositOther = await cappedPoolNFT.userDeposits(otherUser.address);
        expect(userDepositOther).to.equal(parseEther("320"));

        let totalDeposit = await cappedPoolNFT.totalDeposits();
        expect(totalDeposit).to.equal(parseEther("360"));

        let availableTokensByClass = await cappedPoolNFT.getAvailableTokensPerClass();
        expect(availableTokensByClass[0]).to.equal(300);
        expect(availableTokensByClass[1]).to.equal(1000);
        expect(availableTokensByClass[2]).to.equal(2000);
        expect(availableTokensByClass[3]).to.equal(6500);

        let balanceOfDeployer = await cappedPoolNFT.balanceOf(deployer.address, 1);
        expect(balanceOfDeployer).to.equal(40);

        let balanceOfOther = await cappedPoolNFT.balanceOf(otherUser.address, 1);
        expect(balanceOfOther).to.equal(160);
    });
  });
});