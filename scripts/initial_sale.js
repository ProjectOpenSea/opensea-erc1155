const opensea = require('opensea-js')
const { WyvernSchemaName } = require("opensea-js/lib/types")
const OpenSeaPort = opensea.OpenSeaPort;
const Network = opensea.Network;
const MnemonicWalletSubprovider = require('@0x/subproviders').MnemonicWalletSubprovider
const RPCSubprovider = require('web3-provider-engine/subproviders/rpc')
const Web3ProviderEngine = require('web3-provider-engine')

const MNEMONIC = process.env.MNEMONIC
const INFURA_KEY = process.env.INFURA_KEY
const FACTORY_CONTRACT_ADDRESS = process.env.FACTORY_CONTRACT_ADDRESS
const OWNER_ADDRESS = process.env.OWNER_ADDRESS
const NETWORK = process.env.NETWORK
const API_KEY = process.env.API_KEY || "" // API key is optional but useful if you're doing a high volume of requests.

const FIXED_PRICE_OPTION_IDS = ["0", "1", "2"];
const FIXED_PRICES_ETH = [0.1, 0.2, 0.3];
const NUM_FIXED_PRICE_AUCTIONS = [1000, 1000, 1000]; // [2034, 2103, 2202];

if (!MNEMONIC || !INFURA_KEY || !NETWORK || !OWNER_ADDRESS) {
    console.error("Please set a mnemonic, infura key, owner, network, API key, nft contract, and factory contract address.")
    return
}

if (!FACTORY_CONTRACT_ADDRESS) {
    console.error("Please specify a factory contract address.")
    return
}

const BASE_DERIVATION_PATH = `44'/60'/0'/0`

const mnemonicWalletSubprovider = new MnemonicWalletSubprovider({ mnemonic: MNEMONIC, baseDerivationPath: BASE_DERIVATION_PATH})
const infuraRpcSubprovider = new RPCSubprovider({
    rpcUrl: 'https://' + NETWORK + '.infura.io/v3/' + INFURA_KEY,
})

const providerEngine = new Web3ProviderEngine()
providerEngine.addProvider(mnemonicWalletSubprovider)
providerEngine.addProvider(infuraRpcSubprovider)
providerEngine.start();

const seaport = new OpenSeaPort(providerEngine, {
    networkName: NETWORK === 'mainnet' ? Network.Main : Network.Rinkeby,
    apiKey: API_KEY
}, (arg) => console.log(arg))

async function main() {
    // Example: many fixed price auctions for a factory option.
    for (let i = 0; i < FIXED_PRICE_OPTION_IDS.length; i++) {
        const optionId = FIXED_PRICE_OPTION_IDS[i];
        console.log(`Creating fixed price auctions for ${optionId}...`)
        const fixedSellOrders = await seaport.createFactorySellOrders({
            assetId: optionId,
            factoryAddress: FACTORY_CONTRACT_ADDRESS,
            quantity: 1,
            accountAddress: OWNER_ADDRESS,
            startAmount: FIXED_PRICES_ETH[i],
            numberOfOrders: NUM_FIXED_PRICE_AUCTIONS[i],
            schemaName: WyvernSchemaName.ERC1155
        })
        console.log(`Successfully made ${fixedSellOrders.length} fixed-price sell orders! ${fixedSellOrders[0].asset.openseaLink}\n`)
    }
/*
    // Example: many fixed price auctions for multiple factory options.
    console.log("Creating fixed price auctions...")
    const fixedSellOrders = await seaport.createFactorySellOrders({
        assetIds: FIXED_PRICE_OPTION_IDS,
        factoryAddress: FACTORY_CONTRACT_ADDRESS,
        accountAddress: OWNER_ADDRESS,
        startAmount: FIXED_PRICE,
        numberOfOrders: NUM_FIXED_PRICE_AUCTIONS
    })
    console.log(`Successfully made ${fixedSellOrders.length} fixed-price sell orders for multiple assets at once! ${fixedSellOrders[0].asset.openseaLink}\n`)

    // Example: many declining Dutch auction for a factory.
    console.log("Creating dutch auctions...")

    // Expire one day from now
    const expirationTime = Math.round(Date.now() / 1000 + 60 * 60 * 24)
    const dutchSellOrders = await seaport.createFactorySellOrders({
        assetId: DUTCH_AUCTION_OPTION_ID,
        factoryAddress: FACTORY_CONTRACT_ADDRESS,
        accountAddress: OWNER_ADDRESS, 
        startAmount: DUTCH_AUCTION_START_AMOUNT,
        endAmount: DUTCH_AUCTION_END_AMOUNT,
        expirationTime: expirationTime,
        numberOfOrders: NUM_DUTCH_AUCTIONS
    })
    console.log(`Successfully made ${dutchSellOrders.length} Dutch-auction sell orders! ${dutchSellOrders[0].asset.openseaLink}\n`)
*/
}

main()