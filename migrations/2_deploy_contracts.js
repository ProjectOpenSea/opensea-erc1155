const MyCollectible = artifacts.require("./MyCollectible.sol");
// const MyFactory = artifacts.require("./MyFactory.sol")
const MyLootBox = artifacts.require("./MyLootBox.sol");

module.exports = function(deployer, network) {
  // OpenSea proxy registry addresses for rinkeby and mainnet.
  let proxyRegistryAddress
  if (network === 'rinkeby') {
    proxyRegistryAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
  } else {
    proxyRegistryAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  }

  deployer.deploy(MyCollectible, proxyRegistryAddress, {gas: 5000000});
  
  // Uncomment this if you want initial item sale support.
  // deployer.deploy(MyCollectible, proxyRegistryAddress, {gas: 5000000}).then(() => {
  //   return deployer.deploy(MyLootBox, proxyRegistryAddress, MyCollectible.address, {gas: 7000000});
  // }).then(async () => {
  //   const collectible = await MyCollectible.deployed();
  //   return collectible.transferOwnership(MyLootBox.address);
  // }).then(async () => {
  //   console.log(`FACTORY ADDRESS: ${MyLootBox.address}`);
  //   console.log(`COLLECTIBLE ADDRESS: ${MyCollectible.address}`);
  // }).catch((error) => {
  //   console.error(error);
  // });
};
