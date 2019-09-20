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
  uint256 private _currentTokenId = 0;

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

  /**
    * @dev Mints a token to an address with a tokenURI.
    * @param _to address of the future owner of the token
    */
  function mintTo(address _to) public onlyOwner {
    uint256 newTokenId = _getNextTokenId();
    _mint(_to, newTokenId);
    _incrementTokenId();
  }

  /**
    * @dev calculates the next token ID based on value of _currentTokenId
    * @return uint256 for the next token ID
    */
  function _getNextTokenId() private view returns (uint256) {
    return _currentTokenId.add(1);
  }

  /**
    * @dev increments the value of _currentTokenId
    */
  function _incrementTokenId() private  {
    _currentTokenId++;
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
