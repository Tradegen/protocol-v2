const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
/*
describe("MobiusFarmVerifier", () => {
  let deployer;
  let otherUser;

  let bytes;
  let bytesAddress;
  let BytesFactory;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let testToken1;
  let testTokenAddress1;
  let TokenFactory;

  let mobiusLPVerifier;
  let mobiusLPVerifierAddress;
  let MobiusLPVerifierFactory;

  let mobiusFarmVerifier;
  let mobiusFarmVerifierAddress;
  let MobiusFarmVerifierFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    BytesFactory = await ethers.getContractFactory('Bytes');
    bytes = await BytesFactory.deploy();
    await bytes.deployed();
    bytesAddress = bytes.address;

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    MobiusLPVerifierFactory = await ethers.getContractFactory('MobiusLPVerifier', {
        libraries: {
            Bytes: bytesAddress,
        },
      });
    MobiusFarmVerifierFactory = await ethers.getContractFactory('MobiusFarmVerifier', {
        libraries: {
            Bytes: bytesAddress,
        },
      });

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    testToken1 = await TokenFactory.deploy("Test Token 1", "TEST1");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    mobiusLPVerifier = await MobiusLPVerifierFactory.deploy(addressResolverAddress, deployer.address, deployer.address);
    await mobiusLPVerifier.deployed();
    mobiusLPVerifierAddress = mobiusLPVerifier.address;

    let tx = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx.wait();

    let tx2 = await addressResolver.setAssetVerifier(3, mobiusLPVerifierAddress);
    await tx2.wait();
  });

  beforeEach(async () => {
    mobiusFarmVerifier = await MobiusFarmVerifierFactory.deploy(addressResolverAddress);
    await mobiusFarmVerifier.deployed();
    mobiusFarmVerifierAddress = mobiusFarmVerifier.address;
  });
  
  describe("#verify deposit()", () => {
    it('tokens not supported', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'deposit',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amountIn'
            },{
                type: 'uint256',
                name: 'amountOutMin'
            }]
        }, ['1000', '1000']);
    
        let tx = mobiusFarmVerifier.verify(deployer.address, testTokenAddress1, params);
        await expect(tx).to.be.reverted;
      });

    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'deposit',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amountIn'
            },{
                type: 'uint256',
                name: 'amountOutMin'
            }]
        }, ['1000', '1000']);

        let tx = await mobiusLPVerifier.setFarmAddress(testTokenAddress1, 1);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(deployer.address, 1);
        await tx2.wait();

        let tx3 = await assetHandler.setValidAsset(testTokenAddress1, 1);
        await tx3.wait();
  
        let tx4 = await mobiusFarmVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx4).to.emit(mobiusFarmVerifier, "Staked");
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'deposit',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amountIn'
            },{
                type: 'address',
                name: 'amountOutMin'
            }]
        }, ['1000', deployer.address]);
  
        let tx = await mobiusFarmVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx).to.not.emit(mobiusFarmVerifier, "Staked");
    });
  });

  describe("#verify withdraw()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amountIn'
            },{
                type: 'uint256',
                name: 'amountOutMin'
            }]
        }, ['1000', '1000']);
  
        let tx = await mobiusFarmVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx).to.emit(mobiusFarmVerifier, "Unstaked");
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amountIn'
            },{
                type: 'address',
                name: 'amountOutMin'
            }]
        }, ['1000', deployer.address]);
  
        let tx = await mobiusFarmVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx).to.not.emit(mobiusFarmVerifier, "Unstaked");
    });
  });
});*/