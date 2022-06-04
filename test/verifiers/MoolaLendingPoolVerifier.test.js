const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
/*
describe("MoolaLendingPoolVerifier", () => {
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

  let moolaAdapter;
  let moolaAdapterAddress;
  let MoolaAdapterFactory;

  let moolaLendingPoolVerifier;
  let moolaLendingPoolVerifierAddress;
  let MoolaLendingPoolVerifierFactory;

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
    MoolaAdapterFactory = await ethers.getContractFactory('TestMoolaAdapter');
    MoolaLendingPoolVerifierFactory = await ethers.getContractFactory('MoolaLendingPoolVerifier', {
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

    moolaAdapter = await MoolaAdapterFactory.deploy();
    await moolaAdapter.deployed();
    moolaAdapterAddress = moolaAdapter.address;

    let tx = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("MoolaAdapter", moolaAdapterAddress);
    await tx2.wait();
  });

  beforeEach(async () => {
    moolaLendingPoolVerifier = await MoolaLendingPoolVerifierFactory.deploy(addressResolverAddress);
    await moolaLendingPoolVerifier.deployed();
    moolaLendingPoolVerifierAddress = moolaLendingPoolVerifier.address;
  });
  
  describe("#verify deposit()", () => {
    it('tokens not supported', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'deposit',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'reserve'
            },
            {
                type: 'uint256',
                name: 'amountOutMin'
            },
            {
                type: 'uint256',
                name: 'amountOutMin'
            }]
        }, [deployer.address, '1000', '1000']);
    
        let tx = moolaLendingPoolVerifier.verify(deployer.address, testTokenAddress1, params);
        await expect(tx).to.be.reverted;
      });

    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'deposit',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'reserve'
            },
            {
                type: 'uint256',
                name: 'amountOutMin'
            },
            {
                type: 'uint256',
                name: 'amountOutMin'
            }]
        }, [deployer.address, '1000', '1000']);

        let tx = await assetHandler.setValidAsset(deployer.address, 1);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(testTokenAddress1, 1);
        await tx2.wait();

        let tx3 = await moolaAdapter.setUnderlyingAsset(deployer.address);
        await tx3.wait();
  
        let tx4 = await moolaLendingPoolVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx4).to.emit(moolaLendingPoolVerifier, "Deposit");
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'deposit',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'reserve'
            },
            {
                type: 'uint256',
                name: 'amountOutMin'
            },
            {
                type: 'uint256',
                name: 'amountOutMin'
            }]
        }, ['1', '1000', '1000']);
  
        let tx = await moolaLendingPoolVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx).to.not.emit(moolaLendingPoolVerifier, "Deposit");
    });
  });

  describe("#verify borrow()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'borrow',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'reserve'
            },
            {
                type: 'uint256',
                name: 'amountOutMin'
            },
            {
                type: 'uint256',
                name: 'amountOutMin'
            },
            {
                type: 'uint16',
                name: 'amountOutMin'
            }]
        }, [deployer.address, '1000', '1000', '1']);
  
        let tx = await moolaLendingPoolVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx).to.emit(moolaLendingPoolVerifier, "Borrow");
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'borrow',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amountIn'
            },{
                type: 'address',
                name: 'amountOutMin'
            }]
        }, ['1000', deployer.address]);
  
        let tx = await moolaLendingPoolVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx).to.not.emit(moolaLendingPoolVerifier, "Borrow");
    });
  });

  describe("#verify repay()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'repay',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'reserve'
            },
            {
                type: 'uint256',
                name: 'amountOutMin'
            },
            {
                type: 'address',
                name: 'amountOutMin'
            }]
        }, [deployer.address, '1000', deployer.address]);
  
        let tx = await moolaLendingPoolVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx).to.emit(moolaLendingPoolVerifier, "Repay");
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'repay',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amountIn'
            },{
                type: 'address',
                name: 'amountOutMin'
            }]
        }, ['1000', deployer.address]);
  
        let tx = await moolaLendingPoolVerifier.verify(deployer.address, testTokenAddress1, params);
        expect(tx).to.not.emit(moolaLendingPoolVerifier, "Repay");
    });
  });
});*/