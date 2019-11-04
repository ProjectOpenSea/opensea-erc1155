const MyLootBox = artifacts.require("MyLootBox");

// Set to undefined if you want to create your own collectible
const NFT_ADDRESS_TO_USE = '0xfaafdc07907ff5120a76b34b731b278c38d6043c'
// If you want to set preminted token ids for specific classes
const TOKEN_ID_MAPPING = {
  // Gold skin
  0: ['7237005577332281999397856501860761851237635992167078807090459951131355250688', '7237005577332282005674958237247442615073425415374745223192815395595389763584',
    // etc
    ],
  // Neon Skin
  1: ['10855508365998404902212481632990500638275546880548340587544943536885532196864', '10855508365998404946152193780697265985126072843002005500261431648133773787136',
  // etc
  ],
  // NFT Nom
  1: ['10855508365998404902212481632990500638275546880548340587544943536885532196864', '10855508365998404946152193780697265985126072843002005500261431648133773787136',
  // etc
  ],
}

module.exports = function(deployer, network) {
  // OpenSea proxy registry addresses for rinkeby and mainnet.
  let proxyRegistryAddress
  if (network === 'rinkeby') {
    proxyRegistryAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
  } else {
    proxyRegistryAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  }

  deployer.deploy(MyLootBox, proxyRegistryAddress, NFT_ADDRESS_TO_USE, {gas: 5000000})
      .then(setupLootbox);
};

async function setupLootbox() {
  const lootbox = await MyLootBox.deployed();
  for (const box in TOKEN_ID_MAPPING) {
    console.log(`Setting token ids for box ${box}`)
    const tokenIds = TOKEN_ID_MAPPING[box]
    await lootbox.setTokenIdsForClass(box, tokenIds);
  }
}
