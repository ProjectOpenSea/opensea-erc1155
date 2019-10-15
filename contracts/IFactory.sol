pragma solidity ^0.5.11;

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 */
interface IFactory {
  /**
   * Returns the name of this factory.
   */
  function name() external view returns (string memory);

  /**
   * Returns the symbol for this factory.
   */
  function symbol() external view returns (string memory);

  /**
   * Number of options the factory supports.
   */
  function numOptions() external view returns (uint256);

  /**
   * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
   * restrict a total supply per option ID (or overall).
   */
  function canMint(uint256 _optionId, uint256 _amount) external view returns (bool);

  /**
   * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
   * same structure as the ERC1155 metadata.
   */
  function uri(uint256 _optionId) external view returns (string memory);

  /**
   * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
   */
  function supportsFactoryInterface() external view returns (bool);

  /**
    * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
    * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
    * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
    * @param _optionId the option id
    * @param _toAddress address of the future owner of the asset(s)
    * @param _amount amount of the option to mint
    * @param _data Extra data to pass during safeTransferFrom
    */
  function mint(uint256 _optionId, address _toAddress, uint256 _amount, bytes calldata _data) external;

  /**
   * @dev Transfers assets to the _to address, minting them out of the factory if needed.
   * Should call the same logic under `mint`
   * @param _from The address to transfer from (ignored)
   * @param _to The address to transfer to
   * @param _optionId the option id
   * @param _amount amount of the option to mint
   * @param _data Extra data to pass
   */
  function safeTransferFrom(address _from, address _to, uint256 _optionId, uint256 _amount, bytes calldata _data) external;
}