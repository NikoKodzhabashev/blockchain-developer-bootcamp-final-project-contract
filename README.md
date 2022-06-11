## How to run this project locally:

### Prerequisites

- Node.js >= v14
- Truffle and Ganache
- Yarn

### Steps to run it

- Run `yarn install` in project root to install Truffle build and smart contract dependencies
- Run local testnet in port `8545` with an Ethereum client, e.g. Ganache
- `truffle migrate --network development`
- `truffle console --network development`
- Run tests in Truffle console: `test`

### Directory structure

- contracts: Smart contracts that are deployed in the Ropsten testnet.
- migrations: Migration files for deploying contracts in contracts directory.
- test: Tests for smart contracts.
