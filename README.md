## OpenSea ERC-1155 Starter Contracts

- [About these contracts](#about-these-contracts)
  - [Configuring the Lootbox](#configuring-the-lootbox)
  - [Why are some standard methods overridden?](#why-are-some-standard-methods-overridden)
- [Requirements](#requirements)
    - [Node version](#node-version)
  - [Installation](#installation)
  - [Deploying](#deploying)
    - [Deploying to the Rinkeby network.](#deploying-to-the-rinkeby-network)
    - [Deploying to the mainnet Ethereum network.](#deploying-to-the-mainnet-ethereum-network)
    - [Viewing your items on OpenSea](#viewing-your-items-on-opensea)
    - [Troubleshooting](#troubleshooting)
      - [It doesn't compile!](#it-doesnt-compile)
      - [It doesn't deploy anything!](#it-doesnt-deploy-anything)
    - [Minting tokens.](#minting-tokens)
- [License](#license)
    - [ERC1155 Implementation](#erc1155-implementation)

# About these contracts

This is a sample ERC-1155 contract for the purposes of demonstrating integration with the [OpenSea](https://opensea.io) marketplace for crypto collectibles. We also include:
- A script for minting items.
- A factory contract for making sell orders for unminted items (allowing for **gas-free and mint-free presales**).
- A configurable lootbox contract for selling randomized collections of ERC-1155 items.

On top of the features from the [OpenSea ERC721 sample contracts](https://github.com/ProjectOpenSea/opensea-creatures), ERC1155
- supports multiple creators per contract, where only the creator is able to mint more copies
- supports pre-minted items for the lootbox to choose from

## Configuring the Lootbox

Open MyLootbox.sol

1. Change `Class` to reflect your rarity levels.
2. Change `NUM_CLASSES` to reflect how many classes you have (this gets used for sizing fixed-length arrays in Solidity)
3. In `constructor`, set the `OptionSettings` for each of your classes. To do this, as in the example, call `setOptionSettings` with
   1. Your option id,
   2. The number of items to issue when the box is opened,
   3. An array of probabilities (basis points, so integers out of 10,000) of receiving each class. Should add up to 10k and be descending in value.
4. Then follow the instructions below to deploy it! Purchases will auto-open the box. If you'd like to make lootboxes tradable by users (without a purchase auto-opening it), contact us at contact@opensea.io (or better yet, in [Discord](https://discord.gg/ga8EJbv)).

## Why are some standard methods overridden?

This contract overrides the `isApprovedForAll` method in order to whitelist the proxy accounts of OpenSea users. This means that they are automatically able to trade your ERC-1155 items on OpenSea (without having to pay gas for an additional approval). On OpenSea, each user has a "proxy" account that they control, and is ultimately called by the exchange contracts to trade their items.

Note that this addition does not mean that OpenSea itself has access to the items, simply that the users can list them more easily if they wish to do so!

# Requirements

### Node version

Either make sure you're running a version of node compliant with the `engines` requirement in `package.json`, or install Node Version Manager [`nvm`](https://github.com/creationix/nvm) and run `nvm use` to use the correct version of node.

## Installation

Run
```bash
yarn
```

## Deploying

### Deploying to the Rinkeby network.

1. You'll need to sign up for [Infura](https://infura.io). and get an API key.
2. You'll need Rinkeby ether to pay for the gas to deploy your contract. Visit https://faucet.rinkeby.io/ to get some.
3. Using your API key and the mnemonic for your MetaMask wallet (make sure you're using a MetaMask seed phrase that you're comfortable using for testing purposes), run:

```
export INFURA_KEY="<infura_key>"
export MNEMONIC="<metmask_mnemonic>"
truffle migrate --network rinkeby
```

### Deploying to the mainnet Ethereum network.

Make sure your wallet has at least a few dollars worth of ETH in it. Then run:

```
yarn truffle migrate --network live
```

Look for your newly deployed contract address in the logs! 🥳

### Viewing your items on OpenSea

OpenSea will automatically pick up transfers on your contract. You can visit an asset by going to `https://opensea.io/assets/CONTRACT_ADDRESS/TOKEN_ID`.

To load all your metadata on your items at once, visit [https://opensea.io/get-listed](https://opensea.io/get-listed) and enter your address to load the metadata into OpenSea! You can even do this for the Rinkeby test network if you deployed there, by going to [https://rinkeby.opensea.io/get-listed](https://rinkeby.opensea.io/get-listed).

### Troubleshooting

#### It doesn't compile!
Install truffle locally: `yarn add truffle`. Then run `yarn truffle migrate ...`.

You can also debug just the compile step by running `yarn truffle compile`.

#### It doesn't deploy anything!
This is often due to the truffle-hdwallet provider not being able to connect. Go to infura.io and create a new Infura project. Use your "project ID" as your new `INFURA_KEY` and make sure you export that command-line variable above.

### Minting tokens.

After deploying to the Rinkeby network, there will be a contract on Rinkeby that will be viewable on [Rinkeby Etherscan](https://rinkeby.etherscan.io). For example, here is a [recently deployed contract](https://rinkeby.etherscan.io/address/0xeba05c5521a3b81e23d15ae9b2d07524bc453561). You should set this contract address and the address of your Metamask account as environment variables when running the minting script:

```
export OWNER_ADDRESS="<my_address>"
export FACTORY_CONTRACT_ADDRESS="<deployed_contract_address>"
export NETWORK="rinkeby"
node scripts/advanced/mint.js
```

Note: When running the minting script on mainnet, your environment variable needs to be set to `mainnet` not `live`.  The environment variable affects the Infura URL in the minting script, not truffle. When you deploy, you're using truffle and you need to give truffle an argument that corresponds to the naming in truffle.js (`--network live`).  But when you mint, you're relying on the environment variable you set to build the URL (https://github.com/ProjectOpenSea/opensea-creatures/blob/master/scripts/mint.js#L54), so you need to use the term that makes Infura happy (`mainnet`).  Truffle and Infura use the same terminology for Rinkeby, but different terminology for mainnet.  If you start your minting script, but nothing happens, double check your environment variables.

# License

These contracts are available to the public under an MIT License.

### ERC1155 Implementation

To implement the ERC1155 standard, these contracts use the Multi Token Standard by [Horizon Games](https://horizongames.net/), available on [npm](https://www.npmjs.com/package/multi-token-standard) and [github](https://github.com/arcadeum/multi-token-standard) and also under the MIT License.
