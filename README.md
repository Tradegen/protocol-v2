# Tradegen Asset Management Protocol V2

## Purpose

Implementation of a decentralized asset management system on the Celo blockchain.

## Overview

Users can invest in pools of assets (decentralized hedge funds) that are managed by other users or external projects. When users invest in a pool, they receive tokens that represent their share of the assets in the pool. These tokens fluctuate in value based on the price of the pool's underlying assets and lifetime performance. To withdraw from a pool, users can burn their pool tokens and pay a performance fee to the pool manager (if they are withdrawing for a profit). Users receive their share of the pool’s assets when they withdraw.

Pools are represented by smart contracts that pool managers can interact with using the platform’s UI. These contracts send transactions to whitelisted DeFi projects on the pool’s behalf, eliminating the possibility of pool managers withdrawing other users’ investments into their own account or calling unsupported contracts.

In addition to pools, users can also invest in ‘Capped pools’ with a capped supply of pool tokens (each of which is an NFT) and different levels of scarcity (represented by four classes of tokens). These tokens can be traded on the platform’s marketplace or deposited into farms to earn yield while staying invested in the pool. Since there’s a max supply of pool tokens, tokens on the marketplace may trade above mint price based on factors such as pool’s past performance, token class, farm yield, and pool manager’s reputation.

## Disclaimer

These smart contracts have not been audited yet.

## System Design

### Smart Contracts

* MobiusAdapter - Makes calls to contracts in the Mobius protocol.
* MoolaAdapter - Makes calls to contracts in the Moola protocol.
* UbeswapAdapter - Makes calls to the Ubeswap router and farm contracts. Used for calculating price and checking if an address is valid.
* MobiusERC20PriceCalculator - Calculates the price of ERC20 tokens issued by the Mobius protocol.
* MobiusLPTokenPriceCalculator - Calculates the price of LP tokens issued by the Mobius protocol.
* MoolaPriceCalculator - Calculates the price of assets issued by the Moola protocol.
* UbeswapERC20PriceCalculator - Calculates the price of ERC20 tokens supported by Ubeswap.
* UbeswapLPTokenPriceCalculator - Calculates the price of LP tokens issued by Ubeswap.
* ERC20Verifier - Checks if an ERC20 token is valid.
* MobiusLPVerifier - Checks if a LP token created by Mobius is valid.
* MoolaInterestBearingTokenVerifier - Checks if an interest-bearing token created by Moola is valid.
* UbeswapLPVerifier - Checks if a LP token created by Ubeswap is valid.
* MobiusFarmVerifier - Checks if a pool's call to a Mobius farm contract is valid.
* MoolaLendingPoolVerifier - Checks if a pool's call to a Moola lending pool contract is valid.
* UbeswapFarmVerifier - Checks if a pool's call to a Ubeswap farm contract is valid.
* UbeswapRouterVerifier - Checks if a pool's call to the Ubeswap router contract is valid.
* AddressResolver - Stores the address of each contract in the protocol.
* AssetHandler - Tracks whitelisted assets and handles price calculations.
* CappedPool - A pool with a fixed number of tokens, each of which is an NFT.
* CappedPoolFactory - Creates CappedPool contracts.
* CappedPoolNFT - Implements the token logic of a CappedPool.
* CappedPoolNFTFactory - Creates CappedPoolNFT contracts.
* Marketplace - Used for buying/selling CappedPool tokens.
* Pool - A decentralized hedge fund. Stores a collection of assets and is managed by a user or an external contract.
* PoolFactory - Creates Pool contracts.
* PoolManagerLogic - Stores the pool manager logic for a Pool or CappedPool.
* PoolManagerLogicFactory - Creates PoolManagerLogic contracts.
* Registry - Registers, and manages, Pools and CappedPools.
* Settings - Tracks the parameters used throughout the protocol.
* UbeswapPathManager - Stores the optimal path for swapping to/from each whitelisted asset.

## Repository Structure

```
.
├── abi  ## Generated ABIs that developers can use to interact with the system.
├── contract addresses  ## Address of each deployed contract, organized by network.
├── contracts  ## All source code.
│   ├── adapters  ## Adapters used for communicating with external contracts.
│   ├── farming-system  ## A copy of the farming system, used for integration tests.
│   ├── interfaces  ## Interfaces used for defining/calling contracts.
│   ├── libraries  ## Libraries storing helper functions.
│   ├── openzeppelin-solidity  ## Helper contracts provided by OpenZeppelin.
│   ├── price-calculators  ## Price calculators for various types of assets.
│   ├── test  ## Mock contracts used for testing main contracts.
│   ├── verifiers  ## Contracts for verifying external protocols.
├── test ## Source code for testing code in //contracts.
```

## Documentation

To learn more about the Tradegen project, visit the docs at https://docs.tradegen.io.

To learn more about Celo, visit their home page: https://celo.org/.

## License

MIT
