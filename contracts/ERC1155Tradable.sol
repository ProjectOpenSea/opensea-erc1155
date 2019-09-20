pragma solidity ^0.5.11;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import 'multi-token-standard/contracts/tokens/ERC1155/ERC1155Metadata.sol';
import 'multi-token-standard/contracts/tokens/ERC1155/ERC1155MintBurn.sol';

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and implements name() and symbol()
 */
contract ERC1155Tradable is ERC1155Metadata, ERC1155MintBurn, Ownable {
  address proxyRegistryAddress;
  uint256 private _currentTokenID = 0;
  mapping (uint256 => address) public creators;
  // Contract name
  string private _name;
  // Contract symbol
  string private _symbol;

  constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress) public {
    name = _name;
    symbol = _symbol;
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**
    * @dev Gets the contract name, for backwards compatibility with ERC-721 metadata
    * @return string representing the token name
    */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
    * @dev Gets the contract symbol, for backwards compatibility with ERC-721 metadata
    * @return string representing the token symbol
    */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  modifier creatorOnly(uint256 _id) {
    require(creators[_id] == msg.sender, "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

  /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * @param _initialOwner address of the first owner of the token
    * @param _initialSupply amount to supply the first owner
    * @param _url Optional URI for this token type
    */
  function create(
    address _initialOwner,
    uint256 _initialSupply,
    string memory _uri
  ) external returns(uint256 _id) {

    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();
    creators[_id] = msg.sender;
    _mint(_initialOwner, _id, _initialSupply, "");

    if (bytes(_uri).length > 0) {
      emit URI(_uri, _id);
    }
  }

  /**
    * @dev Mints some amount of tokens to an address
    * @param _to          Address of the future owner of the token
    * @param _id          Token ID to mint
    * @param _quantity    Amount of tokens to mint
    * @param _data        Data to pass if receiver is contract
    */
  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) public onlyCreator(_id) {
    _mint(_to, _id, _quantity, _data);
  }

  /**
    * @dev Mint tokens for each id in _ids
    * @param _to          The address to mint tokens to
    * @param _ids         Array of ids to mint
    * @param _quantities  Array of amounts of tokens to mint per id
    * @param _data        Data to pass if receiver is contract
    */
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities,
    bytes memory _data
  ) public {
    for (uint256 i = 0; i < _ids.length; i++) {
      address _id = _ids[i];
      require(creators[_id] == msg.sender, "ERC1155Tradable#batchMint: ONLY_CREATOR_ALLOWED");
    }
    _batchMint(_to, _ids, _quantities, _data);
  }

  /**
    * @dev calculates the next token ID based on value of _currentTokenID
    * @return uint256 for the next token ID
    */
  function _getNextTokenID() private view returns (uint256) {
    return _currentTokenID.add(1);
  }

  /**
    * @dev increments the value of _currentTokenID
    */
  function _incrementTokenTypeId() private  {
    _currentTokenID++;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(
    address owner,
    address operator
  )
    external
    view
    returns (bool isOperator)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}
