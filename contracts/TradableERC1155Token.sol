pragma solidity ^0.5.11;

import 'multi-token-standard/contracts/tokens/ERC1155/ERC1155Metadata.sol';
import 'multi-token-standard/contracts/tokens/ERC1155/ERC1155MintBurn.sol';

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title TradableERC1155Token
 * TradableERC1155Token - ERC1155 contract that whitelists a trading address, adds tokenURI as a method, and has minting functionality.
 */
contract TradableERC1155Token is ERC1155Metadata, ERC1155MintBurn {
  address proxyRegistryAddress;
  uint256 private _currentTokenID = 0;
  mapping (uint256 => address) public creators;
  // Contract name
  string private _name;
  // Contract symbol
  string private _symbol;

  constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress) public {
    proxyRegistryAddress = _proxyRegistryAddress;
    name = _name;
    symbol = _symbol;
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
    require(creators[_id] == msg.sender);
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
    string calldata _uri
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
    * @param _id Token ID to mint copies of
    * @param _to address of the future owner of the token
    */
  function mint(
    uint256 _id,
    address _to,
    uint256 _quantity,
    bytes memory _data
  ) public onlyCreator(_id) {
    _mint(_to, _id, _quantity, _data);
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
