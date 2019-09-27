pragma solidity ^0.5.11;

import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./MyCollectible.sol";
import "./MyFactory.sol";

/**
 * @title MyLootBox
 * MyLootBox - a randomized and openable lootbox of MyCollectibles
 */
contract MyLootBox is MyFactory, Pausable, ReentrancyGuard {

  event LootBoxPurchased(uint256 indexed optionId, address indexed buyer, uint256 count);

  // Must be sorted by rarity
  enum Class {
    Common,
    Rare,
    Epic,
    Legendary,
    Divine,
    Hidden
  }
  uint256 constant NUM_CLASSES = 6;

  struct OptionSettings {
    uint256 price;
    uint256 quantityPerOpen;
    uint256 totalSupply;
    uint16[NUM_CLASSES] classProbabilities;
  }
  mapping (uint256 => OptionSettings) public optionToSettings;
  mapping (uint256 => uint256) public optionToAmountOpened;

  mapping (uint256 => uint256) public classToTokenID;
  uint256 nonce = 0;

  /**
   * @dev Set the settings for a particular lootbox option
   */
  function setOptionSettings(
    Option _option,
    uint256 _price,
    uint256 _quantityPerOpen,
    uint256 _totalSupply,
    uint16[NUM_CLASSES] calldata _classProbabilities
  ) external onlyOwner {

    OptionSettings memory settings = OptionSettings({
      price: _price,
      quantityPerOpen: _quantityPerOpen,
      totalSupply: _totalSupply,
      classProbabilities: _classProbabilities
    });

    optionToSettings[uint256(_option)] = settings;
  }

  /**
   * @notice Buy a particular lootbox option
   * @param _option The Option to open
   * @param _quantity The quantity of lootboxes to open
   */
  function open(
    Option _option,
    uint256 _quantity
  ) public payable whenNotPaused nonReentrant {

    // Load settings for this box option
    uint256 optionId = uint256(_option);
    OptionSettings memory settings = optionToSettings[optionId];

    // Check parameters
    uint256 totalPrice = settings.price * _quantity;
    require(msg.value == totalPrice, "MyLootBox#open: INVALID_PAYMENT");
    require(canMint(_option, _quantity), "MyLootBox#open: CANNOT_MINT");

    // Iterate over the quantity of boxes specified
    for (uint256 i = 0; i < _quantity; i++) {
      // Iterate over the box's set quantity
      for (uint256 j = 0; j < settings.quantityPerOpen; j++) {
        Class class = _pickRandomClass(settings.classProbabilities);
        _mintClass(class, msg.sender, 1);
      }
    }

    // Record how many boxes were opened
    // (Class minting is recorded in the MyCollectible contract)
    optionToAmountOpened[optionId] = optionToAmountOpened[optionId] + _quantity;

    // Event emissions
    emit LootBoxPurchased(optionId, msg.sender, _quantity);
  }

  function canMint(
    Option _option,
    uint256 _amount
  ) public view returns (bool) {
    uint256 optionId = uint256(_option);
    OptionSettings memory settings = optionToSettings[optionId];
    uint256 amountOpened = optionToAmountOpened[optionId];
    return (
      _amount > 0 &&
      _amount + amountOpened <= settings.totalSupply
    );
  }

  function withdraw() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  /////
  // HELPER FUNCTIONS
  /////

  function _mintClass(
    Class _class,
    address _toAddress,
    uint256 _amount
  ) internal {
    MyCollectible openSeaMyCollectible = MyCollectible(nftAddress);
    uint256 id = classToTokenID[uint256(_class)];
    if (id == 0) {
      id = openSeaMyCollectible.create(_toAddress, _amount, "", "");
      classToTokenID[uint256(_class)] = id;
    } else {
      openSeaMyCollectible.mint(_toAddress, id, _amount, "");
    }
  }

  function _pickRandomClass(
    uint16[NUM_CLASSES] memory _classProbabilities
  ) public returns (Class) {
    uint16 value = uint16(_random() % 100);
    // Start at top class (length - 1)
    // skip common (0), we default to it
    for (uint256 i = _classProbabilities.length - 1; i > 0; i--) {
      uint16 probability = _classProbabilities[i];
      if (value < probability) {
        return Class(i);
      } else {
        value = value - probability;
      }
    }
    return Class.Common;
  }

  /**
   * @dev Pseudo-random number generator
   * NOTE: to improve randomness, generate it with an oracle
   */
  function _random() internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, nonce)));
    nonce++;
    return randomNumber;
  }
}
