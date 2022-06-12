const { ethers } = require("hardhat");

const ADDRESS_RESOLVER_ADDRESS_TESTNET = "0x0A6E2fC374700B621f1406e5D46606fA28Ae636e";
const ADDRESS_RESOLVER_ADDRESS_MAINNET = "";

const BYTES_LIBRARY_ADDRESS_TESTNET = "0x0F2E394eFf37322b323784DdA2AC0A16AC4001ca";
const BYTES_LIBRARY_ADDRESS_MAINNET = "";

const MOBIUS_MASTERMIND_ADDRESS_TESTNET = "";
const MOBIUS_MASTERMIND_ADDRESS_MAINNET = "";

const MOBI_TOKEN_ADDRESS_TESTNET = "";
const MOBI_TOKEN_ADDRESS_MAINNET = "";

async function deployAddressResolver() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    
    let addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    let addressResolverAddress = addressResolver.address;
    console.log("AddressResolver: " + addressResolverAddress);
}

async function deployRemainingCoreContracts() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    let UbeswapPathManagerFactory = await ethers.getContractFactory('UbeswapPathManager');
    let SettingsFactory = await ethers.getContractFactory('Settings');
    let MarketplaceFactory = await ethers.getContractFactory('Marketplace');
    let CappedPoolNFTFactoryFactory = await ethers.getContractFactory('CappedPoolNFTFactory');
    let CappedPoolFactoryFactory = await ethers.getContractFactory('CappedPoolFactory');
    let PoolFactoryFactory = await ethers.getContractFactory('PoolFactory');
    let PoolManagerLogicFactoryFactory = await ethers.getContractFactory('PoolManagerLogicFactory');
    let RegistryFactory = await ethers.getContractFactory('Registry');
    
    let assetHandler = await AssetHandlerFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await assetHandler.deployed();
    let assetHandlerAddress = assetHandler.address;
    console.log("AssetHandler: " + assetHandlerAddress);

    let ubeswapPathManager = await UbeswapPathManagerFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await ubeswapPathManager.deployed();
    let ubeswapPathManagerAddress = ubeswapPathManager.address;
    console.log("UbeswapPathManager: " + ubeswapPathManagerAddress);

    let settings = await SettingsFactory.deploy();
    await settings.deployed();
    let settingsAddress = settings.address;
    console.log("Settings: " + settingsAddress);

    let marketplace = await MarketplaceFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await marketplace.deployed();
    let marketplaceAddress = marketplace.address;
    console.log("Marketplace: " + marketplaceAddress);

    let cappedPoolNFTFactory = await CappedPoolNFTFactoryFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await cappedPoolNFTFactory.deployed();
    let cappedPoolNFTFactoryAddress = cappedPoolNFTFactory.address;
    console.log("CappedPoolNFTFactory: " + cappedPoolNFTFactoryAddress);

    let cappedPoolFactory = await CappedPoolFactoryFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await cappedPoolFactory.deployed();
    let cappedPoolFactoryAddress = cappedPoolFactory.address;
    console.log("CappedPoolFactory: " + cappedPoolFactoryAddress);

    let poolFactory = await PoolFactoryFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await poolFactory.deployed();
    let poolFactoryAddress = poolFactory.address;
    console.log("PoolFactory: " + poolFactoryAddress);

    let poolManagerLogicFactory = await PoolManagerLogicFactoryFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await poolManagerLogicFactory.deployed();
    let poolManagerLogicFactoryAddress = poolManagerLogicFactory.address;
    console.log("PoolManagerLogicFactory: " + poolManagerLogicFactoryAddress);

    let registry = await RegistryFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await registry.deployed();
    let registryAddress = registry.address;
    console.log("Registry: " + registryAddress);

    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');

    let addressResolver = AddressResolverFactory.attach(ADDRESS_RESOLVER_ADDRESS_TESTNET);

    let tx = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("UbeswapPathManager", ubeswapPathManagerAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("Settings", settingsAddress);
    await tx3.wait();

    let tx4 = await addressResolver.setContractAddress("Marketplace", marketplaceAddress);
    await tx4.wait();

    let tx5 = await addressResolver.setContractAddress("CappedPoolNFTFactory", cappedPoolNFTFactoryAddress);
    await tx5.wait();

    let tx6 = await addressResolver.setContractAddress("CappedPoolFactory", cappedPoolFactoryAddress);
    await tx6.wait();

    let tx7 = await addressResolver.setContractAddress("PoolFactory", poolFactoryAddress);
    await tx7.wait();

    let tx8 = await addressResolver.setContractAddress("PoolManagerLogicFactory", poolManagerLogicFactoryAddress);
    await tx8.wait();

    let tx9 = await addressResolver.setContractAddress("Registry", registryAddress);
    await tx9.wait();
}

async function deployAdapters() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let MobiusAdapterFactory = await ethers.getContractFactory('MobiusAdapter');
    let MoolaAdapterFactory = await ethers.getContractFactory('MoolaAdapter');
    let UbeswapAdapterFactory = await ethers.getContractFactory('UbeswapAdapter');
    
    let mobiusAdapter = await MobiusAdapterFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await mobiusAdapter.deployed();
    let mobiusAdapterAddress = mobiusAdapter.address;
    console.log("MobiusAdapter: " + mobiusAdapterAddress);

    let moolaAdapter = await MoolaAdapterFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await moolaAdapter.deployed();
    let moolaAdapterAddress = moolaAdapter.address;
    console.log("MoolaAdapter: " + moolaAdapterAddress);

    let ubeswapAdapter = await UbeswapAdapterFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await ubeswapAdapter.deployed();
    let ubeswapAdapterAddress = ubeswapAdapter.address;
    console.log("UbeswapAdapter: " + ubeswapAdapterAddress);

    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');

    let addressResolver = AddressResolverFactory.attach(ADDRESS_RESOLVER_ADDRESS_TESTNET);

    let tx = await addressResolver.setContractAddress("MobiusAdapter", mobiusAdapterAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("MoolaAdapter", moolaAdapterAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("UbeswapAdapter", ubeswapAdapterAddress);
    await tx3.wait();
}

async function deployPriceCalculators() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let MobiusERC20PriceCalculatorFactory = await ethers.getContractFactory('MobiusERC20PriceCalculator');
    let MobiusLPTokenPriceCalculatorFactory = await ethers.getContractFactory('MobiusLPTokenPriceCalculator');
    let MoolaPriceCalculatorFactory = await ethers.getContractFactory('MoolaPriceCalculator');
    let UbeswapERC20PriceCalculatorFactory = await ethers.getContractFactory('UbeswapERC20PriceCalculator');
    let UbeswapLPTokenPriceCalculatorFactory = await ethers.getContractFactory('UbeswapLPTokenPriceCalculator');
    
    let mobiusERC20PriceCalculator = await MobiusERC20PriceCalculatorFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await mobiusERC20PriceCalculator.deployed();
    let mobiusERC20PriceCalculatorAddress = mobiusERC20PriceCalculator.address;
    console.log("MobiusERC20PriceCalculator: " + mobiusERC20PriceCalculatorAddress);

    let mobiusLPTokenPriceCalculator = await MobiusLPTokenPriceCalculatorFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await mobiusLPTokenPriceCalculator.deployed();
    let mobiusLPTokenPriceCalculatorAddress = mobiusLPTokenPriceCalculator.address;
    console.log("MobiusLPTokenPriceCalculator: " + mobiusLPTokenPriceCalculatorAddress);

    let moolaPriceCalculator = await MoolaPriceCalculatorFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await moolaPriceCalculator.deployed();
    let moolaPriceCalculatorAddress = moolaPriceCalculator.address;
    console.log("MoolaPriceCalculator: " + moolaPriceCalculatorAddress);

    let ubeswapERC20PriceCalculator = await UbeswapERC20PriceCalculatorFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await ubeswapERC20PriceCalculator.deployed();
    let ubeswapERC20PriceCalculatorAddress = ubeswapERC20PriceCalculator.address;
    console.log("UbeswapERC20PriceCalculator: " + ubeswapERC20PriceCalculatorAddress);

    let ubeswapLPTokenPriceCalculator = await UbeswapLPTokenPriceCalculatorFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await ubeswapLPTokenPriceCalculator.deployed();
    let ubeswapLPTokenPriceCalculatorAddress = ubeswapLPTokenPriceCalculator.address;
    console.log("UbeswapLPTokenPriceCalculator: " + ubeswapLPTokenPriceCalculatorAddress);

    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');

    let addressResolver = AddressResolverFactory.attach(ADDRESS_RESOLVER_ADDRESS_TESTNET);

    let tx = await addressResolver.setContractAddress("MobiusERC20PriceCalculator", mobiusERC20PriceCalculatorAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("MobiusLPTokenPriceCalculator", mobiusLPTokenPriceCalculatorAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("MoolaPriceCalculator", moolaPriceCalculatorAddress);
    await tx3.wait();

    let tx4 = await addressResolver.setContractAddress("UbeswapERC20PriceCalculator", ubeswapERC20PriceCalculatorAddress);
    await tx4.wait();

    let tx5 = await addressResolver.setContractAddress("UbeswapLPTokenPriceCalculator", ubeswapLPTokenPriceCalculatorAddress);
    await tx5.wait();
}

async function deployBytesLibrary() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let BytesFactory = await ethers.getContractFactory('Bytes');
    bytes = await BytesFactory.deploy();
    await bytes.deployed();
    console.log("Bytes Library: " + bytes.address);
}

async function deployUbeswapAndMoolaAssetVerifiers() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier', {
        libraries: {
            Bytes: BYTES_LIBRARY_ADDRESS_TESTNET,
        },
    });
    let UbeswapLPVerifierFactory = await ethers.getContractFactory('UbeswapLPVerifier', {
        libraries: {
            Bytes: BYTES_LIBRARY_ADDRESS_TESTNET,
        },
    });
    let MoolaInterestBearingTokenVerifierFactory = await ethers.getContractFactory('MoolaInterestBearingTokenVerifier', {
        libraries: {
            Bytes: BYTES_LIBRARY_ADDRESS_TESTNET,
        },
    });
    
    let erc20Verifier = await ERC20VerifierFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await erc20Verifier.deployed();
    let erc20VerifierAddress = erc20Verifier.address;
    console.log("ERC20Verifier: " + erc20VerifierAddress);

    let ubeswapLPVerifier = await UbeswapLPVerifierFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await ubeswapLPVerifier.deployed();
    let ubeswapLPVerifierAddress = ubeswapLPVerifier.address;
    console.log("UbeswapLPVerifier: " + ubeswapLPVerifierAddress);

    let moolaInterestBearingTokenVerifier = await MoolaInterestBearingTokenVerifierFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await moolaInterestBearingTokenVerifier.deployed();
    let moolaInterestBearingTokenVerifierAddress = moolaInterestBearingTokenVerifier.address;
    console.log("MoolaInterestBearingTokenVerifier: " + moolaInterestBearingTokenVerifierAddress);

    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');

    let addressResolver = AddressResolverFactory.attach(ADDRESS_RESOLVER_ADDRESS_TESTNET);

    let tx = await addressResolver.setContractAddress("ERC20Verifier", erc20VerifierAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("UbeswapLPVerifier", ubeswapLPVerifierAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("MoolaInterestBearingTokenVerifier", moolaInterestBearingTokenVerifierAddress);
    await tx3.wait();
}

async function deployMobiusAssetVerifier() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let MobiusLPVerifierFactory = await ethers.getContractFactory('MobiusLPVerifier', {
        libraries: {
            Bytes: BYTES_LIBRARY_ADDRESS_TESTNET,
        },
    });

    let mobiusLPVerifier = await MobiusLPVerifierFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET, MOBIUS_MASTERMIND_ADDRESS_TESTNET, MOBI_TOKEN_ADDRESS_TESTNET);
    await mobiusLPVerifier.deployed();
    let mobiusLPVerifierAddress = mobiusLPVerifier.address;
    console.log("MobiusLPVerifier: " + mobiusLPVerifierAddress);

    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');

    let addressResolver = AddressResolverFactory.attach(ADDRESS_RESOLVER_ADDRESS_TESTNET);

    let tx = await addressResolver.setContractAddress("MobiusPVerifier", mobiusLPVerifierAddress);
    await tx.wait();
}

async function deployContractVerifiers() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let MobiusFarmVerifierFactory = await ethers.getContractFactory('MobiusFarmVerifier', {
        libraries: {
            Bytes: BYTES_LIBRARY_ADDRESS_TESTNET,
        },
    });
    let MoolaLendingPoolVerifierFactory = await ethers.getContractFactory('MoolaLendingPoolVerifier', {
        libraries: {
            Bytes: BYTES_LIBRARY_ADDRESS_TESTNET,
        },
    });
    let UbeswapFarmVerifierFactory = await ethers.getContractFactory('UbeswapFarmVerifier', {
        libraries: {
            Bytes: BYTES_LIBRARY_ADDRESS_TESTNET,
        },
    });
    let UbeswapRouterVerifierFactory = await ethers.getContractFactory('UbeswapRouterVerifier', {
        libraries: {
            Bytes: BYTES_LIBRARY_ADDRESS_TESTNET,
        },
    });
    
    let mobiusFarmVerifier = await MobiusFarmVerifierFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await mobiusFarmVerifier.deployed();
    let mobiusFarmVerifierAddress = mobiusFarmVerifier.address;
    console.log("MobiusFarmVerifier: " + mobiusFarmVerifierAddress);

    let moolaLendingPoolVerifier = await MoolaLendingPoolVerifierFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await moolaLendingPoolVerifier.deployed();
    let moolaLendingPoolVerifierAddress = moolaLendingPoolVerifier.address;
    console.log("MoolaLendingPoolVerifier: " + moolaLendingPoolVerifierAddress);

    let ubeswapFarmVerifier = await UbeswapFarmVerifierFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await ubeswapFarmVerifier.deployed();
    let ubeswapFarmVerifierAddress = ubeswapFarmVerifier.address;
    console.log("UbeswapFarmVerifier: " + ubeswapFarmVerifierAddress);

    let ubeswapRouterVerifier = await UbeswapRouterVerifierFactory.deploy(ADDRESS_RESOLVER_ADDRESS_TESTNET);
    await ubeswapRouterVerifier.deployed();
    let ubeswapRouterVerifierAddress = ubeswapRouterVerifier.address;
    console.log("UbeswapRouterVerifier: " + ubeswapRouterVerifierAddress);

    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');

    let addressResolver = AddressResolverFactory.attach(ADDRESS_RESOLVER_ADDRESS_TESTNET);

    let tx = await addressResolver.setContractAddress("MobiusFarmVerifier", mobiusFarmVerifierAddress);
    await tx.wait();

    let tx2 = await addressResolver.setContractAddress("MoolaLendingPoolVerifier", moolaLendingPoolVerifierAddress);
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("UbeswapFarmVerifier", ubeswapFarmVerifierAddress);
    await tx3.wait();

    let tx4 = await addressResolver.setContractAddress("UbeswapRouterVerifier", ubeswapRouterVerifierAddress);
    await tx4.wait();
}
/*
deployAddressResolver()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })


deployRemainingCoreContracts()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

deployAdapters()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

deployPriceCalculators()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

deployBytesLibrary()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

deployUbeswapAndMoolaAssetVerifiers()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

deployMobiusAssetVerifier()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })*/

deployContractVerifiers()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })