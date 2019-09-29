pragma solidity ^0.5.11;

import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./MyCollectible.sol";
import "./MyFactory.sol";

/**
 * @title MyLootBox
 * MyLootBox - a randomized and openable lootbox of MyCollectibles
 */
contract MyLootBox is Ownable, Pausable, ReentrancyGuard, MyFactory {
  using SafeMath for uint256;

  // Event for logging lootbox opens
  event LootBoxOpened(uint256 indexed optionId, address indexed buyer, uint256 boxesPurchased, uint256 itemsMinted);

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

  // NOTE: Price of the lootbox is set via sell orders on OpenSea
  struct OptionSettings {
    // Number of items to send per open.
    // Set to 0 to disable this Option.
    uint256 quantityPerOpen;
    // Total number of lootbox opens available
    // If zero, it's unlimited
    uint256 totalSupply;
    // Probability out of 100 of receiving each class (descending)
    uint16[NUM_CLASSES] classProbabilities;
  }
  mapping (uint256 => OptionSettings) public optionToSettings;
  mapping (uint256 => uint256) public optionToAmountOpened;
  mapping (uint256 => uint256) public classToTokenId;
  mapping (uint256 => bool) classIsPreminted;
  uint256 nonce = 0;

  constructor(
    address _proxyRegistryAddress,
    address _nftAddress
  ) MyFactory(
    _proxyRegistryAddress,
    _nftAddress
  ) public {
    // Constructor
  }

  //////
  // INITIALIZATION FUNCTIONS FOR OWNER
  //////

  /**
   * @dev If the tokens for some class are pre-minted, the classToTokenId
   * mapping can be updated using this function
   */
  function setTokenIdForClass(
    Class _class,
    uint256 tokenId
  ) external onlyOwner {
    uint256 classId = uint256(_class);
    classIsPreminted[classId] = true;
    classToTokenId[classId] = tokenId;
  }

  /**
   * @dev Set the settings for a particular lootbox option
   */
  function setOptionSettings(
    Option _option,
    uint256 _quantityPerOpen,
    uint256 _totalSupply,
    uint16[NUM_CLASSES] calldata _classProbabilities
  ) external onlyOwner {

    OptionSettings memory settings = OptionSettings({
      quantityPerOpen: _quantityPerOpen,
      totalSupply: _totalSupply,
      classProbabilities: _classProbabilities
    });

    optionToSettings[uint256(_option)] = settings;
  }

  ///////
  // MAIN FUNCTIONS
  //////

  /**
   * @dev Main minting logic for lootboxes
   * This is called via safeTransferFrom.
   * NOTE: prices and fees are determined by the sell order on OpenSea.
   */
  function _mint(
    Option _option,
    address _toAddress,
    uint256 _amount,
    bytes memory /* _data */
  ) internal whenNotPaused nonReentrant {
    require(_canMint(_option, _amount), "MyLootBox#open: CANNOT_MINT");

    // Load settings for this box option
    uint256 optionId = uint256(_option);
    OptionSettings memory settings = optionToSettings[optionId];

    // Iterate over the quantity of boxes specified
    for (uint256 i = 0; i < _amount; i++) {
      // Iterate over the box's set quantity
      for (uint256 j = 0; j < settings.quantityPerOpen; j++) {
        Class class = _pickRandomClass(settings.classProbabilities);
        _sendTokenWithClass(class, _toAddress, 1);
      }
    }

    // Record how many boxes were opened
    // (Class minting is recorded in the MyCollectible contract)
    optionToAmountOpened[optionId] = optionToAmountOpened[optionId] + _amount;

    // Event emissions
    uint256 totalMinted = _amount.mul(settings.quantityPerOpen);
    if (totalMinted > 0) {
      emit LootBoxOpened(optionId, _toAddress, _amount, totalMinted);
    }
  }

  /**
   * When _owner is the contract owner, this will return how many
   * times a particular Option can still be opened.
   * NOTE: called by `canMint`
   */
  function balanceOf(
    address _owner,
    uint256 _optionId
  ) public view returns (uint256) {
    if (_owner != owner()) {
      // No one accept the contract owner offers any lootboxes
      return 0;
    }
    OptionSettings memory settings = optionToSettings[_optionId];
    uint256 amountOpened = optionToAmountOpened[_optionId];
    if (amountOpened > settings.totalSupply) {
      // This option may have been disabled by the dev
      // by setting totalSupply to zero
      return 0;
    }
    return settings.totalSupply.sub(amountOpened);
  }

  function withdraw() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  /////
  // IFactory methods
  /////

  function name() external view returns (string memory) {
    return "My Loot Box";
  }

  function symbol() external view returns (string memory) {
    return "MYLOOT";
  }

  /////
  // HELPER FUNCTIONS
  /////

  // Returns the tokenId sent to _toAddress
  function _sendTokenWithClass(
    Class _class,
    address _toAddress,
    uint256 _amount
  ) internal returns (uint256) {
    uint256 classId = uint256(_class);
    MyCollectible nftContract = MyCollectible(nftAddress);
    uint256 tokenId = classToTokenId[classId];
    if (classIsPreminted[classId]) {
      nftContract.safeTransferFrom(
        address(this),
        _toAddress,
        tokenId,
        _amount,
        ""
      );
    } else if (tokenId == 0) {
      tokenId = nftContract.create(_toAddress, _amount, "", "");
      classToTokenId[classId] = tokenId;
    } else {
      nftContract.mint(_toAddress, tokenId, _amount, "");
    }
    return tokenId;
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
