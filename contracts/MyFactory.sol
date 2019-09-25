pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IFactory.sol";
import "./MyCollectible.sol";
import "./Strings.sol";

// WIP
contract MyFactory is IFactory, Ownable {
  using Strings for string;

  address public proxyRegistryAddress;
  address public nftAddress;
  string internal baseMetadataURI = "https://opensea-creatures-api.herokuapp.com/api/factory/";

  /**
   * Enforce the existence of only 100 items per option/token ID
   */
  uint256 SUPPLY_PER_TOKEN_ID = 100;

  /**
   * Three different options for minting MyCollectibles (basic, premium, and gold).
   */
  enum Option {
    Basic,
    Premium,
    Gold
  }
  uint256 constant NUM_OPTIONS = 3;
  mapping (uint256 => uint256) public optionToTokenID;

  /**
   * @dev Require msg.sender to be the owner proxy or owner.
   */
  modifier onlyOwner() {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    require(
      address(proxyRegistry.proxies(owner())) == msg.sender ||
      owner() == msg.sender,
      "MyFactory#mint: NOT_AUTHORIZED_TO_MINT"
    );
    _;
  }

  constructor(address _proxyRegistryAddress, address _nftAddress) public {
    proxyRegistryAddress = _proxyRegistryAddress;
    nftAddress = _nftAddress;
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
  ) public onlyOwner {
    Option option = Option(_optionId);
    require(canMint(option, _amount), "MyFactory#mint: CANNOT_MINT_MORE");
    MyCollectible openSeaMyCollectible = MyCollectible(nftAddress);
    uint256 id = optionToTokenID[_optionId];
    if (id == 0) {
      id = openSeaMyCollectible.create(_toAddress, _amount, "", _data);
      optionToTokenID[_optionId] = id;
    } else {
      openSeaMyCollectible.mint(_toAddress, id, _amount, _data);
    }
  }

  function canMint(Option _option, uint256 _amount) public view returns (bool) {
    uint256 optionId = uint256(_option);
    return balanceOf(owner(), optionId) >= _amount;
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
    uint256 _optionId,
    uint256 _amount,
    bytes memory _data
  ) public {
    mint(_optionId, _to, _amount, _data);
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
   * Get the factory's ownership
   * Hack to get things to work automatically on OpenSea.
   */
  function balanceOf(address _owner, uint256 _optionId) public view returns (uint256) {
    if (owner != owner()) {
      return 0;
    }
    uint256 id = optionToTokenID[_optionId];
    if (id == 0) {
      // Haven't minted yet
      return SUPPLY_PER_TOKEN_ID;
    }

    MyCollectible openSeaMyCollectible = MyCollectible(nftAddress);
    uint256 currentSupply = openSeaMyCollectible.totalSupply(id);
    return SUPPLY_PER_TOKEN_ID - currentSupply;
  }
}
