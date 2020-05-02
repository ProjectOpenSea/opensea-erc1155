pragma solidity ^0.5.11;

import "./ERC1155Tradable.sol";

/**
 * @title MyCollectible
 * MyCollectible - a contract for my semi-fungible tokens.
 */
contract MyCollectible is ERC1155Tradable {
  constructor(address _proxyRegistryAddress)
  ERC1155Tradable(
    "MyCollectible",
    "MCB",
    _proxyRegistryAddress
  ) public {
    _setBaseMetadataURI("https://opensea-creatures-api.herokuapp.com/api/creature/");
  }

  function contractURI() public view returns (string memory) {
    return "https://opensea-creatures-api.herokuapp.com/contract/opensea-erc1155";
  }
}
