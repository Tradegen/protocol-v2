# Tradegen Asset Management Protocol V2

## Purpose

Implementation of a decentralized asset management system on the Celo blockchain.

## Overview

Users can invest in pools of assets (decentralized hedge funds) that are managed by other users or external projects. When users invest in a pool, they receive tokens that represent their share of the assets in the pool. These tokens fluctuate in value based on the price of the pool's underlying assets and lifetime performance. To withdraw from a pool, users can burn their pool tokens and pay a performance fee to the pool manager (if they are withdrawing for a profit). Users receive their share of the pool’s assets when they withdraw.

Pools are represented by smart contracts that pool managers can interact with using the platform’s UI. These contracts send transactions to whitelisted DeFi projects on the pool’s behalf, eliminating the possibility of pool managers withdrawing other users’ investments into their own account or calling unsupported contracts.

In addition to pools, users can also invest in ‘Capped pools’ with a capped supply of pool tokens (each of which is an NFT) and different levels of scarcity (represented by four classes of tokens). These tokens can be traded on the platform’s marketplace or deposited into farms to earn yield while staying invested in the pool. Since there’s a max supply of pool tokens, tokens on the marketplace may trade above mint price based on factors such as pool’s past performance, token class, farm yield, and pool manager’s reputation.

## Disclaimer

These smart contracts have not been audited yet.

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
