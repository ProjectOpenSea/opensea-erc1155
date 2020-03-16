pragma solidity ^0.5.11;

import "./MyCollectible.sol";
import "./MyFactory.sol";

contract TestForReentrancyAttack is MyCollectible {
  address public factoryAddress;
  bool private inMintingCall = false;

  constructor(address _proxyRegistryAddress)
    MyCollectible(_proxyRegistryAddress) public {}

  function setFactoryAddress(address _factoryAddress) public {
    factoryAddress = _factoryAddress;
  }

  function create(
    address _addr,
    uint256 _amount,
    string calldata,
    bytes calldata _b
  ) external returns (uint256) {
    if (!inMintingCall) {
      inMintingCall = true;
      MyFactory factory = MyFactory(factoryAddress);
      factory.mint(1, _addr, _amount, _b);
    }
    inMintingCall = false;
    return 0;
  }

  function mint(address, uint256, uint256, bytes memory) public {}
}
