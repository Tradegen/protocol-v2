const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const Web3 = require("web3");
const { ethers } = require("hardhat");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');

describe("ERC20Verifier", () => {
  let deployer;
  let otherUser;

  let testToken1;
  let testToken2;
  let mockStablecoin;
  let testTokenAddress1;
  let testTokenAddress2;
  let mockStablecoinAddress;
  let TokenFactory;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let ERC20Verifier;
  let ERC20VerifierAddress;
  let ERC20VerifierFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    testToken1 = await TokenFactory.deploy("Test Token 1", "TEST1");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    testToken2 = await TokenFactory.deploy("Test Token 2", "TEST2");
    await testToken2.deployed();
    testTokenAddress2 = testToken2.address;

    mockStablecoin = await TokenFactory.deploy("Stablecoin", "SGD");
    await mockStablecoin.deployed();
    mockStablecoinAddress = mockStablecoin.address;

    let tx = await addressResolver.setContractVerifier(mockStablecoinAddress, otherUser.address);
    await tx.wait();
  });

  beforeEach(async () => {
    ERC20Verifier = await ERC20VerifierFactory.deploy();
    await ERC20Verifier.deployed();
    ERC20VerifierAddress = ERC20Verifier.address;
  });
  
  describe("#verify", () => {
    
    it("verify with correct format and approved spender", async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [mockStablecoinAddress, '1000']);

      let tx = await ERC20Verifier.verify(deployer.address, deployer.address, params);
      
      expect(tx).to.emit(ERC20Verifier, "Approve").withArgs(
        deployer.address,
        mockStablecoinAddress,
        1000,
        1
      );
    });

    it("verify with correct format and unsupported spender", async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [testTokenAddress2, '1000']);

      let tx = ERC20Verifier.verify(deployer.address, deployer.address, params);
      await expect(tx).to.be.reverted;
    });

    it("verify with incorrect format", async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'address',
            name: 'value'
        }]
      }, [mockStablecoinAddress, testTokenAddress2]);
  
      let tx = await ERC20Verifier.verify(deployer.address, deployer.address, params);
      await expect(tx).to.be.reverted;
    });
  });
  
  describe("#getBalance", () => {
    it("get balance", async () => {
      const value = await ERC20Verifier.getBalance(deployer.address, testTokenAddress1);
      
      expect(value).to.equal(parseEther("1000000000"));
    });
  });

  describe("#getDecimals", () => {
    it("get decimals", async () => {
      const value = await ERC20Verifier.getDecimals(testTokenAddress1);
      
      expect(value).to.equal(18);
    });
  });

  describe("#prepareWithdrawal", () => {
    it("prepare withdrawal", async () => {
      const data = await ERC20Verifier.prepareWithdrawal(deployer.address, testTokenAddress1, parseEther("1"));
      
      expect(data[0]).to.equal(testTokenAddress1);
      expect(data[1]).to.equal(parseEther("1000000000"));
      expect(data[2].length).to.equal(0);
      expect(data[3].length).to.equal(0);
    });
  });
});