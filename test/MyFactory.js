/* Contracts in this test */
const MyFactory = artifacts.require("../contracts/MyFactory.sol");
const TestForReentrancyAttack = artifacts.require("../contracts/TestForReentrancyAttack.sol");

/* Utility functions */
const expectThrow = require('./helpers/expectThrow.js');

contract("MyFactory - ERC 1155", (accounts) => {
	var myFactory,
		myCollectible,
		proxy,
		owner = accounts[0],
		userA = accounts[1];

	// Rinkeby proxy address for test, doesn't actually work in the test
	// since the contract does not exist in the test environment.
	var proxyAddress = '0xf57b2c51ded3a29e6891aba85459d600256cf317';

	before(async () => {
		myCollectible = await TestForReentrancyAttack.new(proxyAddress);
		myFactory = await MyFactory.new(proxyAddress, myCollectible.address);
		await myCollectible.setFactoryAddress(myFactory.address);
	});

	/**
	 * NOTE: This check is difficult to test in a development
	 * environment, due to the OwnableDelegateProxy. To get around
	 * this, in order to test this function below, you'll need to:
	 *
	 * 1. go to MyFactory.sol, and
	 * 2. modify _isOwnerOrProxy
	 *
	 * --> Modification is:
	 *      comment out
	 *         return owner() == _address || address(proxyRegistry.proxies(owner())) == _address;
	 *      replace with
	 *         return true;
	 * Then run, you'll get the reentrant error, which passes the test
	 **/

	describe('Re-Entrancy Check', () => {
		it('Should have the correct factory address set',
			() => myCollectible.factoryAddress()
			.then((_factoryAddress) => {
				assert.equal(myFactory.address, _factoryAddress);
			})
		);

		it('Minting from factory should disallow re-entrancy attack',
			() => expectThrow(
				myFactory.mint(1, userA, 1, "0x0", {from: owner}),
				'reentrant'
			)
		);
	});

});
