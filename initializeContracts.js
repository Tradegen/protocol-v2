const { ethers } = require("hardhat");
const { parseEther } = require("@ethersproject/units");

const BYTES_LIBRARY_ADDRESS_TESTNET = "0x0F2E394eFf37322b323784DdA2AC0A16AC4001ca";
const BYTES_LIBRARY_ADDRESS_MAINNET = "";

const ADDRESS_RESOLVER_ADDRESS_TESTNET = "0x0A6E2fC374700B621f1406e5D46606fA28Ae636e";
const ADDRESS_RESOLVER_ADDRESS_MAINNET = "";

const SETTINGS_ADDRESS_TESTNET = "0x6Ed65D527C472ac5Dc9d223DeeFB9751dd82B2bA";
const SETTINGS_ADDRESS_MAINNET = "";

const ASSET_HANDLER_ADDRESS_TESTNET = "0x0173dee5b5D5d47D4c12c62fA6dccfCb18fEbec3";
const ASSET_HANDLER_ADDRESS_MAINNET = "";

const UBESWAP_PATH_MANAGER_ADDRESS_TESTNET = "0x521B823eb64Fa18fF4A3D381ABC7465a51bE4dED";
const UBESWAP_PATH_MANAGER_ADDRESS_MAINNET = "";

const UBESWAP_ERC20_PRICE_CALCULATOR_ADDRESS_TESTNET = "0x363E535cFCDB8FC3808Af5E2Ab142DFd575aa991";
const UBESWAP_ERC20_PRICE_CALCULATOR_ADDRESS_MAINNET = "";

const UBESWAP_LP_TOKEN_PRICE_CALCULATOR_ADDRESS_TESTNET = "0x6d070a433F2F520bF5442D2e8F8d1930ddA0826b";
const UBESWAP_LP_TOKEN_PRICE_CALCULATOR_ADDRESS_MAINNET = "";

const ERC20_VERIFIER_ADDRESS_TESTNET = "0x0fFfb2104e1ccEAE1Aa9C742dA8E44D5Df5eCED7";
const ERC20_VERIFIER_ADDRESS_MAINNET = "";

const UBESWAP_LP_VERIFIER_ADDRESS_TESTNET = "0xB7f56dc4F4e24C7512cb7f598216e8E9c283C4Bb";
const UBESWAP_LP_VERIFIER_ADDRESS_MAINNET = "";

const UBESWAP_ROUTER_VERIFIER_ADDRESS_TESTNET = "0x3838685190e9B74917a398436141E5D58eDA8A27";
const UBESWAP_ROUTER_VERIFIER_ADDRESS_MAINNET = "";

const UBESWAP_FARM_VERIFIER_ADDRESS_TESTNET = "0xC03B88001D463855Ae6aB1088cf5A9c9483a4Df7";
const UBESWAP_FARM_VERIFIER_ADDRESS_MAINNET = "";

const FARMING_SYSTEM_POOL_MANAGER_ADDRESS_TESTNET = "";
const FARMING_SYSTEM_POOL_MANAGER_ADDRESS_MAINNET = "";

const UBESWAP_POOL_MANAGER_TESTNET = "0x9Ee3600543eCcc85020D6bc77EB553d1747a65D2";
const UNISWAP_V2_FACTORY_TESTNET = "0x62d5b84be28a183abb507e125b384122d2c25fae";
const UBESWAP_ROUTER_TESTNET = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";

const mcUSD_TESTNET = "0x71DB38719f9113A36e14F409bAD4F07B58b4730b"
const CELO_TESTNET = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9"
const UBE_TESTNET = "0x00Be915B9dCf56a3CBE739D9B9c202ca692409EC"

const UBE_mcUSD_LP_TESTNET = "0xb83eF6517b03daA9d1397536E477A446A3Bbb73c"

const UBE_mcUSD_FARM_TESTNET = "0x342B20b1290a442eFDBEbFD3FE781FE79b3124b7"

async function setParameterValues() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let SettingsFactory = await ethers.getContractFactory('Settings');

    let settings = SettingsFactory.attach(SETTINGS_ADDRESS_TESTNET);

    let tx = await settings.setParameterValue("TimeBetweenFeeSnapshots", 86400 * 7);
    await tx.wait();

    let tx2 = await settings.setParameterValue("MarketplaceProtocolFee", 100);
    await tx2.wait();

    let tx3 = await settings.setParameterValue("MarketplaceAssetManagerFee", 200);
    await tx3.wait();

    let tx4 = await settings.setParameterValue("MaximumPerformanceFee", 3000);
    await tx4.wait();

    let tx5 = await settings.setParameterValue("MaximumTimeBetweenPerformanceFeeUpdates", 86400);
    await tx5.wait();

    let tx6 = await settings.setParameterValue("MaximumNumberOfPositionsInPool", 7);
    await tx6.wait();

    let tx7 = await settings.setParameterValue("MaximumNumberOfPoolsPerUser", 2);
    await tx7.wait();

    let tx8 = await settings.setParameterValue("MaximumNumberOfCappedPoolTokens", 1000000);
    await tx8.wait();

    let tx9 = await settings.setParameterValue("MinimumNumberOfCappedPoolTokens", 100);
    await tx9.wait();

    let tx10 = await settings.setParameterValue("MaximumCappedPoolSeedPrice", parseEther("1000"));
    await tx10.wait();

    let tx11 = await settings.setParameterValue("MinimumCappedPoolSeedPrice", parseEther("0.01"));
    await tx11.wait();
}

async function setPoolManagerAddress() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');

    let addressResolver = AddressResolverFactory.attach(ADDRESS_RESOLVER_ADDRESS_TESTNET);

    let tx = await addressResolver.setContractAddress("PoolManager", FARMING_SYSTEM_POOL_MANAGER_ADDRESS_TESTNET);
    await tx.wait();
}

async function setUbeswapAddresses() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');

    let addressResolver = AddressResolverFactory.attach(ADDRESS_RESOLVER_ADDRESS_TESTNET);

    let tx = await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER_TESTNET);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("UbeswapPoolManager", UBESWAP_POOL_MANAGER_TESTNET);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("UniswapV2Factory", UNISWAP_V2_FACTORY_TESTNET);
    await tx3.wait();
}

async function setVerifiers() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');

    let addressResolver = AddressResolverFactory.attach(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    
    let tx = await addressResolver.setContractAddress("Operator", deployer.address);
    await tx.wait();
    
    //Add asset verifiers to AddressResolver
    let tx2 = await addressResolver.setAssetVerifier(1, ERC20_VERIFIER_ADDRESS_TESTNET);
    await tx2.wait();

    let tx3 = await addressResolver.setAssetVerifier(2, UBESWAP_LP_VERIFIER_ADDRESS_TESTNET);
    await tx3.wait();

    //Add contract verifier to AddressResolver
    let tx4 = await addressResolver.setContractVerifier(UBESWAP_ROUTER_TESTNET, UBESWAP_ROUTER_VERIFIER_ADDRESS_TESTNET);
    await tx4.wait();

    let tx5 = await addressResolver.setContractVerifier(UBE_mcUSD_FARM_TESTNET, UBESWAP_FARM_VERIFIER_ADDRESS_TESTNET);
    await tx5.wait();
}

async function initializeAssetHandler() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');

    let assetHandler = AssetHandlerFactory.attach(ASSET_HANDLER_ADDRESS_TESTNET);

    //Add asset types to AssetHandler
    let tx = await assetHandler.addAssetType(1, UBESWAP_ERC20_PRICE_CALCULATOR_ADDRESS_TESTNET);
    await tx.wait();

    let tx2 = await assetHandler.addAssetType(2, UBESWAP_LP_TOKEN_PRICE_CALCULATOR_ADDRESS_TESTNET);
    await tx2.wait();

    //Set stablecoin address
    let tx3 = await assetHandler.setStableCoinAddress(mcUSD_TESTNET);
    await tx3.wait();

    let tx4 = await assetHandler.addCurrencyKey(1, CELO_TESTNET);
    await tx4.wait();

    let tx5 = await assetHandler.addCurrencyKey(1, UBE_TESTNET);
    await tx5.wait();

    let tx6 = await assetHandler.addCurrencyKey(2, UBE_mcUSD_LP_TESTNET);
    await tx6.wait();
    
    //Check if contract was initialized correctly
    const assetsForType1 = await assetHandler.getAvailableAssetsForType(1);
    const assetsForType2 = await assetHandler.getAvailableAssetsForType(2);
    const stableCoinAddress = await assetHandler.getStableCoinAddress();
    const priceCalculator1 = await assetHandler.assetTypeToPriceCalculator(1);
    const priceCalculator2 = await assetHandler.assetTypeToPriceCalculator(2);
    console.log(stableCoinAddress);
    console.log(assetsForType1);
    console.log(assetsForType2);
    console.log(priceCalculator1);
    console.log(priceCalculator2);
}

async function initializeUbeswapPathManager() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let UbeswapPathManagerFactory = await ethers.getContractFactory('UbeswapPathManager');

    let pathManager = UbeswapPathManagerFactory.attach(UBESWAP_PATH_MANAGER_ADDRESS_TESTNET);
  
    //Set forward paths
    let tx = await pathManager.setPath(mcUSD_TESTNET, UBE_TESTNET, [mcUSD_TESTNET, CELO_TESTNET, UBE_TESTNET]);
    let tx2 = await pathManager.setPath(mcUSD_TESTNET, CELO_TESTNET, [mcUSD_TESTNET, CELO_TESTNET]);
    await tx.wait();
    await tx2.wait();
  
    //Set backward paths
    let tx3 = await pathManager.setPath(UBE_TESTNET, mcUSD_TESTNET, [UBE_TESTNET, CELO_TESTNET, mcUSD_TESTNET]);
    let tx4 = await pathManager.setPath(CELO_TESTNET, mcUSD_TESTNET, [CELO_TESTNET, mcUSD_TESTNET]);
    await tx3.wait();
    await tx4.wait();
    
    //Check if forward paths were initialized correctly
    let forwardPath1 = await pathManager.getPath(mcUSD_TESTNET, UBE_TESTNET);
    let forwardPath2 = await pathManager.getPath(mcUSD_TESTNET, CELO_TESTNET);
    console.log(forwardPath1);
    console.log(forwardPath2);
  
    //Check if backward paths were initialized correctly
    let backwardPath1 = await pathManager.getPath(UBE_TESTNET, mcUSD_TESTNET);
    let backwardPath2 = await pathManager.getPath(CELO_TESTNET, mcUSD_TESTNET);
    console.log(backwardPath1);
    console.log(backwardPath2);
  }

async function setFarmAddress() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let UbeswapLPVerifierFactory = await ethers.getContractFactory('UbeswapLPVerifier', {
        libraries: {
            Bytes: BYTES_LIBRARY_ADDRESS_TESTNET,
        },
    });

    let ubeswapLPVerifier = UbeswapLPVerifierFactory.attach(UBESWAP_LP_VERIFIER_ADDRESS_TESTNET);

    let tx = await ubeswapLPVerifier.setFarmAddress(UBE_mcUSD_LP_TESTNET, UBE_mcUSD_FARM_TESTNET, UBE_TESTNET);
    await tx.wait();
}
/*
setParameterValues()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

setPoolManagerAddress()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

setUbeswapAddresses()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

setVerifiers()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

initializeAssetHandler()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

initializeUbeswapPathManager()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })*/

setFarmAddress()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })