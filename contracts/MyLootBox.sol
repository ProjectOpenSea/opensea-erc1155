pragma solidity ^0.5.11;

import "./MyCollectible.sol";
import "./MyFactory.sol";

/**
 * @title MyLootBox
 * MyLootBox - a randomized and openable lootbox of MyCollectibles
 */
contract MyLootBox is MyFactory {

  event LootBoxPurchased(uint256 indexed id, address indexed buyer, uint256 count);

  // enum Rarity {
  //   Common,
  //   Rare,
  //   Epic,
  //   Legendary,
  //   Divine,
  //   Hidden
  // }

  struct BoxType {
    uint256 id;
    uint256 price;
    // uint256 quantityPerOpen;
    uint256 totalSupply;
    uint256[] rarityDropRates;
  }

  BoxType[] boxTypes;
  uint256 totalRarities = 0;
  mapping (uint256 => uint256) public rarityToTokenID;
  uint256 nonce = 0;

  function addBoxType(
    uint256 _price,
    uint256 _quantityPerOpen,
    uint256 _totalSupply,
    uint256[] _rarityDropRates
  ) public onlyOwner {

    // require(_rarityDropRates.length == Rarity.length, "MyLootBox#addBoxType: WRONG_DROPRATES_LENGTH");

    MyCollectible collectible = MyCollectible(nftAddress);
    uint256 id = collectible.create(msg.sender, 0, "");

    BoxType memory box = BoxType({
      id: boxTypes.length,
      price: _price,
      quantityPerOpen: _quantityPerOpen,
      totalSupply: _totalSupply,
      rarityDropRates: _rarityDropRates
    });

    boxTypes.push(box);
  }

  function open(uint256 _boxIndex) public payable {
    require(_boxIndex < boxTypes.length, "MyLootBox#open: INVALID_ID");
    BoxType box = boxTypes[_boxIndex];
    uint256 price = box.price;
    require(msg.value >= price, "MyLootBox#open: INSUFFICIENT_FUNDS");
    address(this).transfer(price);

    uint256 random = _random();
    MyCollectible collectible = MyCollectible(nftAddress);
    for (uint256 i = 0; i < box.rarityDropRates.length; i++) {
      uint256 tokenId = rarityToTokenID[i];
      uint256 dropRate = box.rarityDropRates[i];
      if (random % 100 < dropRate * 100) {
        collectible.mint(msg.sender, tokenId, 1, "");
      }
    }

    emit LootBoxPurchased(_boxIndex, msg.sender, 1);
  }

  function withdraw() public onlyOwner {
    owner().transfer(address(this).balance);
  }

  /**
   * @dev Pseudo-random number generator
   */
  function _random() internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce)));
    nonce++;
    return randomNumber;
  }
}
