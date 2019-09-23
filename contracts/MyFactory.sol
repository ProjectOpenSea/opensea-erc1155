pragma solidity ^0.5.11;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IFactory.sol";
import "./MyCollectible.sol";
import "./MyLootBox.sol";
import "./Strings.sol";

contract MyFactory is IFactory, Ownable {
  using Strings for string;

  address public proxyRegistryAddress;
  address public nftAddress;
  address public lootBoxNftAddress;
  string internal baseMetadataURI = "https://opensea-creatures-api.herokuapp.com/api/factory/";

  /**
   * Enforce the existence of only 100 items.
   */
  uint256 TOTAL_SUPPLY = 100;

  /**
   * Three different options for minting MyCollectibles (basic, premium, and gold).
   */
  uint256 NUM_OPTIONS = 3;
  uint256 SINGLE_ITEM_OPTION = 0;
  uint256 MULTIPLE_ITEM_OPTION = 1;
  uint256 LOOTBOX_OPTION = 2;
  uint256 NUM_ITEMS_IN_MULTIPLE_ITEM_OPTION = 4;

  constructor(address _proxyRegistryAddress, address _nftAddress) public {
    proxyRegistryAddress = _proxyRegistryAddress;
    nftAddress = _nftAddress;
    lootBoxNftAddress = address(new MyLootBox(_proxyRegistryAddress, address(this)));
  }

  function name() external view returns (string memory) {
    return "My Collectible Pre-Sale";
  }

  function symbol() external view returns (string memory) {
    return "MCP";
  }

  function supportsFactoryInterface() public view returns (bool) {
    return true;
  }

  function numOptions() public view returns (uint256) {
    return NUM_OPTIONS;
  }

  function mint(
    uint256 _optionId,
    address _toAddress,
    uint256 _amount,
    bytes memory _data
  ) public {
    // Must be sent from the owner proxy or owner.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    require(address(proxyRegistry.proxies(owner())) == msg.sender || owner() == msg.sender || msg.sender == lootBoxNftAddress, "MyFactory#mint: NOT_AUTHORIZED_TO_MINT");
    require(canMint(_optionId, _amount), "MyFactory#mint: CANNOT_MINT_MORE");

    MyCollectible openSeaMyCollectible = MyCollectible(nftAddress);
    if (_optionId == SINGLE_ITEM_OPTION) {
      openSeaMyCollectible.create(_toAddress, _amount, _data);
    } else if (_optionId == MULTIPLE_ITEM_OPTION) {
      for (uint256 i = 0; i < NUM_ITEMS_IN_MULTIPLE_ITEM_OPTION; i++) {
        openSeaMyCollectible.create(_toAddress, _amount, _data);
      }
    } else if (_optionId == LOOTBOX_OPTION) {
      MyLootBox openSeaMyLootBox = MyLootBox(lootBoxNftAddress);
      openSeaMyLootBox.create(_toAddress, _amount, _data);
    }
  }

  function canMint(uint256 _optionId, uint256 _amount) public view returns (bool) {
    if (_optionId >= NUM_OPTIONS) {
      return false;
    }

    MyCollectible openSeaMyCollectible = MyCollectible(nftAddress);
    uint256 creatureSupply = openSeaMyCollectible.totalSupply();

    uint256 numItemsAllocated = 0;
    if (_optionId == SINGLE_ITEM_OPTION) {
      numItemsAllocated = 1;
    } else if (_optionId == MULTIPLE_ITEM_OPTION) {
      numItemsAllocated = NUM_ITEMS_IN_MULTIPLE_ITEM_OPTION;
    } else if (_optionId == LOOTBOX_OPTION) {
      MyLootBox openSeaMyLootBox = MyLootBox(lootBoxNftAddress);
      numItemsAllocated = openSeaMyLootBox.itemsPerLootbox();
    }
    return creatureSupply < TOTAL_SUPPLY.sub(numItemsAllocated.mul(_amount));
  }

  function uri(uint256 _optionId) public view returns (string memory) {
    return Strings.strConcat(
      baseMetadataURI,
      Strings.uint2str(_optionId)
    );
  }

  /**
   * Hack to get things to work automatically on OpenSea.
   * Use safeTransferFrom so the frontend doesn't have to worry about different method names.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenID,
    uint256 _amount,
    bytes memory _data
  ) public {
    mint(_tokenId, _to, _amount, _data);
  }

  /**
   * Hack to get things to work automatically on OpenSea.
   * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    if (owner() == _owner && _owner == _operator) {
      return true;
    }

    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (owner() == _owner && address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return false;
  }

  /**
   * Hack to get things to work automatically on OpenSea.
   */
  function balanceOf(address _owner, uint256 _id) public view returns (uint256 _amount) {
    if (owner == owner()) {
      return TOTAL_SUPPLY;
    } else {
      return 0;
    }
  }
}
