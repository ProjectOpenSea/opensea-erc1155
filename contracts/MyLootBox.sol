pragma solidity ^0.5.11;

import "./TradableERC1155Token.sol";
import "./MyCollectible.sol";
import "./MyFactory.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title MyLootBox
 *
 * MyLootBox - a tradeable loot box of Creatures.
 */
contract MyLootBox is TradableERC1155Token {
    uint256 NUM_CREATURES_PER_BOX = 3;
    uint256 OPTION_ID = 0;
    address factoryAddress;

    constructor(address _proxyRegistryAddress, address _factoryAddress) TradeableERC721Token("MyLootBox", "LOOTBOX", _proxyRegistryAddress) public {
        factoryAddress = _factoryAddress;
        _setBaseMetadataURI("https://opensea-creatures-api.herokuapp.com/api/box/");
    }

    function unpack(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);

        // Insert custom logic for configuring the item here.
        for (uint256 i = 0; i < NUM_CREATURES_PER_BOX; i++) {
            // Mint the ERC721 item(s).
            Factory factory = Factory(factoryAddress);
            factory.mint(OPTION_ID, msg.sender);
        }

        // Burn the presale item.
        _burn(msg.sender, _tokenId);
    }

    function itemsPerLootbox() public view returns (uint256) {
        return NUM_CREATURES_PER_BOX;
    }
}
