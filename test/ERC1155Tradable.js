/* Contracts in this test */
const ERC1155Tradable = artifacts.require("../contracts/ERC1155Tradable.sol");

/* Necessary packages */
const BN = web3.utils.BN;

/* Utility functions */
const expectThrow = require('./helpers/expectThrow.js');

contract("ERC1155Tradable - ERC 1155", (accounts) => {
	var instance,
		owner = accounts[0],
		creator = accounts[1],
		userA = accounts[2],
		userB = accounts[3];

	var name = 'ERC-1155 Test Contract',
		symbol = 'ERC1155Test';

	var initialTokenId = 1;
		initialTokenSupply = new BN(2, 10),
		mintAmount = new BN(2, 10);

	var overflowNumber = (new BN(2, 10)).pow(new BN(256, 10)).sub(new BN(1, 10));

	// Rinkeby proxy address for test, doesn't actually work in the test
	// since the contract does not exist in the test environment.
	var proxyAddress = '0xf57b2c51ded3a29e6891aba85459d600256cf317';

	before(async () => {
		instance = await ERC1155Tradable.new(name, symbol, proxyAddress);
	});

	describe('Setup & Defaults', () => {
		it('Verify the name and symbol are set',
			() => instance.name()
			.then((_name) => {
				assert.equal(name, _name);
				return instance.symbol();
			})
			.then((_symbol) => {
				assert.equal(symbol, _symbol);
			})
		);
	});

	describe('Creating tokens', () => {
		it('Owner can create tokens',
			() => instance.create(owner, 0, "", "0x0", {from: owner})
			.then((_tx) => {
				assert.ok(_tx, "Failed to create token:" + _tx);
				return instance.uri(initialTokenId);
			})
			.then((_uri) => {
				assert.equal(_uri, String(initialTokenId));
			})
		);

		it('Non-owner can not create tokens',
			() => expectThrow(instance.create(userA, 0, "", "0x0", {from: userA}))
		);
	});

	describe('Minting', () => {
		it('Mint some tokens, get correct totalSupply back',
			() => instance.mint(userA, initialTokenId, mintAmount, "0x0", {from: owner})
			.then(() => {
				return instance.totalSupply(initialTokenId);
			})
			.then((_supply) => {
				assert(mintAmount.eq(_supply));
				initialTokenSupply = _supply
			})
		);

		it('Minting should not overflow',
			() => expectThrow(
				instance.mint(userB, initialTokenId, overflowNumber, "0x0", {from: owner}),
				'OVERFLOW'
			)
		);
	});

	describe('Batch Minting', () => {
		it('Batch mint some tokens, get correct totalSupply back',
			() => instance.batchMint(userA, [initialTokenId], [mintAmount], "0x0", {from: owner})
			.then(() => {
				return instance.totalSupply(initialTokenId);
			})
			.then((_supply) => {
				assert(initialTokenSupply.add(mintAmount).eq(_supply));
				initialTokenSupply = _supply;
			})
		);

		it('Batch minting should not overflow',
			() => expectThrow(
				instance.mint(userB, initialTokenId, overflowNumber, "0x0", {from: owner}),
				'OVERFLOW'
			)
		);
	});

});
