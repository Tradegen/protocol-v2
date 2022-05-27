const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');

describe("UbeswapRouterVerifier", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let ubeswapAdapter;
  let ubeswapAdapterAddress;
  let UbeswapAdapterFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let testToken1;
  let testToken2;
  let mockStablecoin;
  let testTokenAddress1;
  let testTokenAddress2;
  let mockStablecoinAddress;
  let TokenFactory;

  let testPriceCalculator1;
  let testPriceCalculator2;
  let testPriceCalculatorAddress1;
  let testPriceCalculatorAddress2;
  let PriceCalculatorFactory;

  let ubeswapRouterVerifier;
  let ubeswapRouterVerifierAddress;
  let UbeswapRouterVerifierFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    UbeswapAdapterFactory = await ethers.getContractFactory('TestUbeswapAdapter');
    TokenFactory = await ethers.getContractFactory('TestTokenERC20');
    PriceCalculatorFactory = await ethers.getContractFactory('TestPriceCalculator');
    UbeswapRouterVerifierFactory = await ethers.getContractFactory('UbeswapRouterVerifier');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    ubeswapAdapter = await UbeswapAdapterFactory.deploy(addressResolverAddress);
    await ubeswapAdapter.deployed();
    ubeswapAdapterAddress = ubeswapAdapter.address;

    testPriceCalculator1 = await PriceCalculatorFactory.deploy();
    await testPriceCalculator1.deployed();
    testPriceCalculatorAddress1 = testPriceCalculator1.address;

    testPriceCalculator2 = await PriceCalculatorFactory.deploy();
    await testPriceCalculator2.deployed();
    testPriceCalculatorAddress2 = testPriceCalculator2.address;

    testToken1 = await TokenFactory.deploy("Test Token 1", "TEST1");
    await testToken1.deployed();
    testTokenAddress1 = testToken1.address;

    testToken2 = await TokenFactory.deploy("Test Token 2", "TEST2");
    await testToken2.deployed();
    testTokenAddress2 = testToken2.address;

    mockStablecoin = await TokenFactory.deploy("Stablecoin", "SGD");
    await mockStablecoin.deployed();
    mockStablecoinAddress = mockStablecoin.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    await addressResolver.setContractAddress("UbeswapAdapter", ubeswapAdapterAddress);
    await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);

    await assetHandler.addAssetType(1, testPriceCalculatorAddress1);
    await assetHandler.addAssetType(2, testPriceCalculatorAddress2);
    await assetHandler.addCurrencyKey(1, testTokenAddress1);
    await assetHandler.addCurrencyKey(2, testTokenAddress2);
    await assetHandler.setStableCoinAddress(mockStablecoinAddress);
  });

  beforeEach(async () => {
    ubeswapRouterVerifier = await UbeswapRouterVerifierFactory.deploy();
    await ubeswapRouterVerifier.deployed();
    ubeswapRouterVerifierAddress = ubeswapRouterVerifier.address;
  });
  
  describe("#verify swapExactTokensForTokens()", () => {
    it('correct format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
          name: 'swapExactTokensForTokens',
          type: 'function',
          inputs: [{
              type: 'uint256',
              name: 'amountIn'
          },{
              type: 'uint256',
              name: 'amountOutMin'
          },{
              type: 'address[]',
              name: 'path'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, ['1000', '1000', [mockStablecoinAddress, testTokenAddress1], deployer.address, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(deployer.address, deployer.address, params);
      expect(tx).to.emit(ubeswapRouterVerifier, "Swap");
      await tx.wait();
    });

    it('wrong format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
          name: 'swapExactTokensForTokens',
          type: 'function',
          inputs: [{
              type: 'uint256',
              name: 'amountIn'
          },{
              type: 'uint256',
              name: 'amountOutMin'
          },{
              type: 'address[]',
              name: 'path'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'address',
              name: 'other'
          }]
      }, ['1000', '1000', [mockStablecoinAddress, testTokenAddress1], deployer.address, otherUser.address]);
  
      let tx = ubeswapRouterVerifier.verify(deployer.address, deployer.address, params);
      await expect(tx).to.be.reverted;
    });

    it('correct format but unsupported sender', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
          name: 'swapExactTokensForTokens',
          type: 'function',
          inputs: [{
              type: 'uint256',
              name: 'amountIn'
          },{
              type: 'uint256',
              name: 'amountOutMin'
          },{
              type: 'address[]',
              name: 'path'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, ['1000', '1000', [mockStablecoinAddress, testTokenAddress1], otherUser.address, '1000000']);
  
      let tx = ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);
      await expect(tx).to.be.reverted;
    });
  });

  describe("#verify addLiquidity()", () => {
    it('correct format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'addLiquidity',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'tokenA'
        },{
            type: 'address',
            name: 'tokenB'
        },{
            type: 'uint256',
            name: 'amountADesired'
        },{
            type: 'uint256',
            name: 'amountBDesired'
        },{
            type: 'uint256',
            name: 'amountAMin'
        },{
            type: 'uint256',
            name: 'amountBMin'
        },{
            type: 'address',
            name: 'to'
        },{
            type: 'uint256',
            name: 'deadline'
        }]
    }, [mockStablecoinAddress, testTokenAddress1, '1000', '1000', '1000', '1000', deployer.address, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(deployer.address, deployer.address, params);
      expect(tx).to.emit(ubeswapRouterVerifier, "AddedLiquidity");
      await tx.wait();
    });

    it('wrong format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'addLiquidity',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'tokenA'
        },{
            type: 'address',
            name: 'tokenB'
        },{
            type: 'uint256',
            name: 'amountADesired'
        },{
            type: 'uint256',
            name: 'amountBDesired'
        },{
            type: 'uint256',
            name: 'amountAMin'
        },{
            type: 'uint256',
            name: 'amountBMin'
        },{
            type: 'address',
            name: 'to'
        },{
            type: 'uint256',
            name: 'deadline'
        },{
            type: 'uint256',
            name: 'other'
        }]
      }, [mockStablecoinAddress, testTokenAddress1, testPriceCalculatorAddress1, '1000', '1000', '1000', deployer.address, '1000000', '42']);
  
      let tx = ubeswapRouterVerifier.verify(deployer.address, deployer.address, params);
      await expect(tx).to.be.reverted;
    });

    it('correct format but unsupported sender', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'addLiquidity',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'tokenA'
        },{
            type: 'address',
            name: 'tokenB'
        },{
            type: 'uint256',
            name: 'amountADesired'
        },{
            type: 'uint256',
            name: 'amountBDesired'
        },{
            type: 'uint256',
            name: 'amountAMin'
        },{
            type: 'uint256',
            name: 'amountBMin'
        },{
            type: 'address',
            name: 'to'
        },{
            type: 'uint256',
            name: 'deadline'
        }]
      }, [mockStablecoinAddress, testTokenAddress1, '1000', '1000', '1000', '1000', addressResolverAddress, '1000000']);
  
      let tx = ubeswapRouterVerifier.verify(deployer.address, deployer.address, params);
      await expect(tx).to.be.reverted;
    });
  });

  describe("#verify removeLiquidity()", () => {
    it('correct format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'removeLiquidity',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'tokenA'
        },{
            type: 'address',
            name: 'tokenB'
        },{
            type: 'uint256',
            name: 'liquidity'
        },{
            type: 'uint256',
            name: 'amountAMin'
        },{
            type: 'uint256',
            name: 'amountBMin'
        },{
            type: 'address',
            name: 'to'
        },{
            type: 'uint256',
            name: 'deadline'
        }]
      }, [mockStablecoinAddress, testTokenAddress1, '1000', '1000', '1000', deployer.address, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(deployer.address, deployer.address, params);
      expect(tx).to.emit(ubeswapRouterVerifier, "RemovedLiquidity");
      await tx.wait();
    });

    it('wrong format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'removeLiquidity',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'tokenA'
        },{
            type: 'address',
            name: 'tokenB'
        },{
            type: 'uint256',
            name: 'liquidity'
        },{
            type: 'uint256',
            name: 'amountAMin'
        },{
            type: 'uint256',
            name: 'amountBMin'
        },{
            type: 'address',
            name: 'to'
        },{
            type: 'uint256',
            name: 'deadline'
        },{
            type: 'uint256',
            name: 'other'
        }]
      }, [mockStablecoinAddress, testTokenAddress1, testPriceCalculatorAddress1, '1000', '1000', deployer.address, '1000000', '42']);
  
      let tx = ubeswapRouterVerifier.verify(deployer.address, deployer.address, params);
      await expect(tx).to.be.reverted;
    });

    it('correct format but unsupported sender', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'removeLiquidity',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'tokenA'
        },{
            type: 'address',
            name: 'tokenB'
        },{
            type: 'uint256',
            name: 'liquidity'
        },{
            type: 'uint256',
            name: 'amountAMin'
        },{
            type: 'uint256',
            name: 'amountBMin'
        },{
            type: 'address',
            name: 'to'
        },{
            type: 'uint256',
            name: 'deadline'
        }]
      }, [mockStablecoinAddress, testTokenAddress1, '1000', '1000', '1000', addressResolverAddress, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(deployer.address, deployer.address, params);
      await expect(tx).to.be.reverted;
    });
  });
});