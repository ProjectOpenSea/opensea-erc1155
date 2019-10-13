const MyCollectible = artifacts.require("MyCollectible");
const MyLootBox = artifacts.require("MyLootBox");

// Set to false if you only want the collectible to deploy
const ENABLE_LOOTBOX = true
// If you want to set preminted token ids for specific classes
const TOKEN_IDS_FOR_CLASSES = [] // [3, 3, 3, 3, 2, 1]

module.exports = function(deployer, network) {
  // OpenSea proxy registry addresses for rinkeby and mainnet.
  let proxyRegistryAddress
  if (network === 'rinkeby') {
    proxyRegistryAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
  } else {
    proxyRegistryAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  }

  if (!ENABLE_LOOTBOX) {
    deployer.deploy(MyCollectible, proxyRegistryAddress, {gas: 5000000});
  } else {
    deployer.deploy(MyCollectible, proxyRegistryAddress, {gas: 5000000}).then(() => {
      return deployer.deploy(MyLootBox, proxyRegistryAddress, MyCollectible.address, {gas: 5000000});
    }).then(async () => {
      const collectible = await MyCollectible.deployed();
      await collectible.transferOwnership(MyLootBox.address);

      if (TOKEN_IDS_FOR_CLASSES.length) {
        const lootbox = await MyLootBox.deployed();
        await lootbox.setTokenIdsForClasses(TOKEN_IDS_FOR_CLASSES);
      }
    });
  }
};
