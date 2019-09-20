pragma solidity ^0.5.11;

import "./TradableERC1155Token.sol";

/**
 * @title MyCollectible
 * MyCollectible - a contract for my semi-fungible tokens.
 */
contract MyCollectible is TradableERC1155Token {
  constructor(address _proxyRegistryAddress) TradableERC1155Token("MyCollectible", "MCB",_proxyRegistryAddress) public {
    _setBaseMetadataURI("https://opensea-creatures-api.herokuapp.com/api/creature/");
  }
}
