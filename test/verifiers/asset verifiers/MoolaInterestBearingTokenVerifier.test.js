const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const Web3 = require("web3");
const { ethers } = require("hardhat");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
/*
describe("MoolaInterestBearingTokenVerifier", () => {
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

  let bytes;
  let bytesAddress;
  let BytesFactory;

  let moolaAdapter;
  let moolaAdapterAddress;
  let MoolaAdapterFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let moolaTokenVerifier;
  let moolaTokenVerifierAddress;
  let MoolaTokenVerifierFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    BytesFactory = await ethers.getContractFactory('Bytes');
    bytes = await BytesFactory.deploy();
    await bytes.deployed();
    bytesAddress = bytes.address;

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    MoolaAdapterFactory = await ethers.getContractFactory('TestMoolaAdapter');
    AssetHandlerFactory = await ethers.getContractFactory('TestAssetHandler');
    MoolaTokenVerifierFactory = await ethers.getContractFactory('MoolaInterestBearingTokenVerifier', {
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

    testToken2 = await TokenFactory.deploy("Test Token 2", "TEST2");
    await testToken2.deployed();
    testTokenAddress2 = testToken2.address;

    mockStablecoin = await TokenFactory.deploy("Stablecoin", "SGD");
    await mockStablecoin.deployed();
    mockStablecoinAddress = mockStablecoin.address;

    moolaAdapter = await MoolaAdapterFactory.deploy();
    await moolaAdapter.deployed();
    moolaAdapterAddress = moolaAdapter.address;

    assetHandler = await AssetHandlerFactory.deploy();
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    let tx = await addressResolver.setContractVerifier(mockStablecoinAddress, otherUser.address);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("MoolaAdapter", moolaAdapterAddress);
    await tx3.wait();
  });

  beforeEach(async () => {
    moolaTokenVerifier = await MoolaTokenVerifierFactory.deploy(addressResolverAddress);
    await moolaTokenVerifier.deployed();
    moolaTokenVerifierAddress = moolaTokenVerifier.address;
  });
  
  describe("#verify", () => {
    it("approve() with correct format and approved spender", async () => {
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

      let tx = await moolaTokenVerifier.verify(deployer.address, deployer.address, params);
      
      expect(tx).to.emit(moolaTokenVerifier, "Approve").withArgs(
        deployer.address,
        mockStablecoinAddress,
        1000
      );
    });

    it("approve() with correct format and unsupported spender", async () => {
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

      let tx = moolaTokenVerifier.verify(deployer.address, deployer.address, params);
      await expect(tx).to.be.reverted;
    });

    it("redeem() with correct format and unsupported asset", async () => {
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

        let tx = await moolaAdapter.setUnderlyingAsset(deployer.address);
        await tx.wait();
  
        let tx2 = moolaTokenVerifier.verify(deployer.address, deployer.address, params);
        await expect(tx2).to.be.reverted;
      });

    it("redeem() with correct format and supported asset", async () => {
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

        let tx = await moolaAdapter.setUnderlyingAsset(deployer.address);
        await tx.wait();

        let tx2 = await assetHandler.setValidAsset(deployer.address, 1);
        await tx2.wait();
  
        let tx3 = moolaTokenVerifier.verify(deployer.address, deployer.address, params);
        expect(tx3).to.emit(moolaTokenVerifier, "Redeem").withArgs(
            deployer.address,
            mockStablecoinAddress,
            1000
          );
      });

    it("verify with incorrect format", async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'disapprove',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'address',
            name: 'value'
        }]
      }, [mockStablecoinAddress, testTokenAddress2]);
  
      let tx = await moolaTokenVerifier.verify(deployer.address, deployer.address, params);
      expect(tx).to.not.emit(moolaTokenVerifier, "Approve");
    });
  });
});*/