/* libraries used */

const truffleAssert = require('truffle-assertions');


/* Contracts in this test */

const ERC1155Tradable = artifacts.require("../contracts/ERC1155Tradable.sol");
const MockProxyRegistry = artifacts.require(
  "../contracts/MockProxyRegistry.sol"
);


/* Useful aliases */

const toBN = web3.utils.toBN;


contract("ERC1155Tradable - ERC 1155", (accounts) => {
  const NAME = 'ERC-1155 Test Contract';
  const SYMBOL = 'ERC1155Test';
  const URI_ROOT = 'https://a.b.c/def/hji/';
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

  const INITIAL_TOKEN_ID = 1;
  const NON_EXISTENT_TOKEN_ID = 99999999;
  const INITIAL_TOKEN_SUPPLY = 2;
  const MINT_AMOUNT = 2;

  const OVERFLOW_NUMBER = toBN(2, 10).pow(toBN(256, 10)).sub(toBN(1, 10));

  const owner = accounts[0];
  const creator = accounts[1];
  const userA = accounts[2];
  const userB = accounts[3];
  const proxyForOwner = accounts[5];

  let instance;
  let proxy;

  // Keep track of token ids as we progress through the tests, rather than
  // hardcoding numbers that we will haev to change if we add/move tests.
  let tokenId = 0;

  // Because we need to deploy and use a mock ProxyRegistry, we deploy our own
  // instance of ERC1155Tradable instead of using the one that Truffle deployed.
  
  before(async () => {
    proxy = await MockProxyRegistry.new();
    await proxy.setProxy(owner, proxyForOwner);
    instance = await ERC1155Tradable.new(NAME, SYMBOL, proxy.address);
  });

  describe('#constructor()', () => {
    it('should set the token name and symbol', async () => {
      const name = await instance.name();
      assert.equal(name, NAME);
      const symbol = await instance.symbol();
      assert.equal(symbol, SYMBOL);
      // We cannot check the proxyRegistryAddress as there is no accessor for it
    });
  });

  describe('#create()', () => {
    it('should allow the contract owner to create tokens with zero supply',
       async () => {
         tokenId += 1;
         truffleAssert.eventEmitted(
           await instance.create(owner, 0, "", "0x0", { from: owner }),
           'TransferSingle',
           {
             _operator: owner,
             _from: ZERO_ADDRESS,
             _to: owner,
             _id: toBN(tokenId),
             _amount: toBN(0)
           }
         );
         const supply = await instance.tokenSupply(tokenId);
         assert.ok(supply.eq(toBN(0)));
       });

    it('should allow the contract owner to create tokens with initial supply',
       async () => {
         tokenId += 1;
         truffleAssert.eventEmitted(
           await instance.create(owner, 100, "", "0x0", { from: owner }),
           'TransferSingle',
           {
             _operator: owner,
             _from: ZERO_ADDRESS,
             _to: owner,
             _id: toBN(tokenId),
             _amount: toBN(100)
           }
         );
         const supply = await instance.tokenSupply(tokenId);
         assert.ok(supply.eq(toBN(100)));
       });

    // We check some of this in the other create() tests but this makes it
    // explicit and is more thorough.
    it('should set tokenSupply on creation',
       async () => {
         tokenId += 1;
         truffleAssert.eventEmitted(
           await instance.create(owner, 33, "", "0x0", { from: owner }),
           'TransferSingle',
           { _id: toBN(tokenId) }
         );
         const balance = await instance.balanceOf(owner, tokenId);
         assert.ok(balance.eq(toBN(33)));
         const supply = await instance.tokenSupply(tokenId);
         assert.ok(supply.eq(toBN(33)));
         assert.ok(supply.eq(balance));
       });

    it('should increment the token type id',
       async () => {
         // We can't check this with an accessor, so we make an explicit check
         // that it increases in consecutive creates() using the value emitted
         // in their events.
         tokenId += 1;
         await truffleAssert.eventEmitted(
           await instance.create(owner, 0, "", "0x0", { from: owner }),
           'TransferSingle',
           { _id: toBN(tokenId) }
         );
         tokenId += 1;
         await truffleAssert.eventEmitted(
           await instance.create(owner, 0, "", "0x0", { from: owner }),
           'TransferSingle',
           { _id: toBN(tokenId) }
         );
       });

    it('should not allow a non-owner to create tokens',
       async () => {
         truffleAssert.fails(
           instance.create(userA, 0, "", "0x0", { from: userA }),
           truffleAssert.ErrorType.revert,
           'caller is not the owner'
         );
       });

    it('should allow the contract owner to create tokens and emit a URI',
       async () => {
         tokenId += 1;
         truffleAssert.eventEmitted(
           await instance.create(owner, 0, URI_ROOT, "0x0", { from: owner }),
           'URI',
           {
             _uri: URI_ROOT,
             _id: toBN(tokenId)
           }
         );
       });

    it('should not emit a URI if none is passed',
       async () => {
         tokenId += 1;
         truffleAssert.eventNotEmitted(
           await instance.create(owner, 0, "", "0x0", { from: owner }),
           'URI'
         );
       });
  });

  describe('#totalSupply()', () => {
    it('should return correct value for token supply',
       async () => {
         tokenId += 1;
         await instance.create(owner, 100, "", "0x0", { from: owner });
         const balance = await instance.balanceOf(owner, tokenId);
         assert.ok(balance.eq(toBN(100)));
         // Use the created getter for the map
         const supplyGetterValue = await instance.tokenSupply(tokenId);
         assert.ok(supplyGetterValue.eq(toBN(100)));
         // Use the hand-crafted accessor
         const supplyAccessorValue = await instance.totalSupply(tokenId);
         assert.ok(supplyAccessorValue.eq(toBN(100)));
         // Make explicitly sure everything mateches
         assert.ok(supplyGetterValue.eq(balance));
         assert.ok(supplyAccessorValue.eq(balance));
       });

    it('should return zero for non-existent token',
       async () => {
         await truffleAssert.passes(
           instance.balanceOf(owner, NON_EXISTENT_TOKEN_ID)
         );
         const supplyAccessorValue = await instance.totalSupply(
           NON_EXISTENT_TOKEN_ID
         );
         assert.ok(supplyAccessorValue.eq(toBN(0)));
       });
  });

  describe('#setCreator()', () => {
    it('should allow the token creator to set creator to another address',
       async () => {
         instance.setCreator(userA, [INITIAL_TOKEN_ID], {from: owner});
         const tokenCreator = await instance.creators(INITIAL_TOKEN_ID);
         assert.equal(tokenCreator, userA);
       });

    it('should allow the new creator to set creator to another address',
       async () => {
         await instance.setCreator(creator, [INITIAL_TOKEN_ID], {from: userA});
         const tokenCreator = await instance.creators(INITIAL_TOKEN_ID);
         assert.equal(tokenCreator, creator);
       });

    it('should not allow the token creator to set creator to 0x0',
       () => truffleAssert.fails(
         instance.setCreator(
           ZERO_ADDRESS,
           [INITIAL_TOKEN_ID],
           { from: creator }
         ),
         truffleAssert.ErrorType.revert,
         'ERC1155Tradable#setCreator: INVALID_ADDRESS.'
       ));

    it('should not allow a non-token-creator to set creator',
       // Check both a user and the owner of the contract
       async () => {
         await truffleAssert.fails(
           instance.setCreator(userA, [INITIAL_TOKEN_ID], {from: userA}),
           truffleAssert.ErrorType.revert,
           'ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED'
         );
         await truffleAssert.fails(
           instance.setCreator(owner, [INITIAL_TOKEN_ID], {from: owner}),
           truffleAssert.ErrorType.revert,
           'ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED'
         );
       });
  });

  describe('#mint()', () => {
    it('should allow creator to mint tokens',
       async () => {
         await instance.mint(
           userA,
           INITIAL_TOKEN_ID,
           MINT_AMOUNT,
           "0x0",
           { from: creator }
         );
         let supply = await instance.totalSupply(INITIAL_TOKEN_ID);
         assert.equal(supply, MINT_AMOUNT);
       });

    it('should update token totalSupply when minting', async () => {
         let supply = await instance.totalSupply(INITIAL_TOKEN_ID);
         assert.equal(supply, MINT_AMOUNT);
         await instance.mint(
           userA,
           INITIAL_TOKEN_ID,
           MINT_AMOUNT,
           "0x0",
           { from: creator }
         );
         supply = await instance.totalSupply(INITIAL_TOKEN_ID);
         assert.equal(supply, MINT_AMOUNT * 2);
    });

    it('should not overflow token balances',
       async () => {
         const supply = await instance.totalSupply(INITIAL_TOKEN_ID);
         assert.equal(supply, INITIAL_TOKEN_SUPPLY + MINT_AMOUNT);
         await truffleAssert.fails(
           instance.mint(
             userB,
             INITIAL_TOKEN_ID,
             OVERFLOW_NUMBER,
             "0x0",
             {from: creator}
           ),
           truffleAssert.ErrorType.revert,
           'OVERFLOW'
         );
       });
  });

  describe('#batchMint()', () => {
    it('should correctly set totalSupply',
       async () => {
         await instance.batchMint(
           userA,
           [INITIAL_TOKEN_ID],
           [MINT_AMOUNT],
           "0x0",
           { from: creator }
         );
         const supply = await instance.totalSupply(INITIAL_TOKEN_ID);
         assert.equal(supply, INITIAL_TOKEN_SUPPLY + (MINT_AMOUNT * 2));
       });

    it('should not overflow token balances',
       () => truffleAssert.fails(
         instance.batchMint(
           userB,
           [INITIAL_TOKEN_ID],
           [OVERFLOW_NUMBER],
           "0x0",
           { from: creator }
         ),
         truffleAssert.ErrorType.revert,
         'OVERFLOW'
       )
      );

    it('should require that caller has permission to mint each token',
       async () => truffleAssert.fails(
         instance.batchMint(
           userA,
           [INITIAL_TOKEN_ID],
           [MINT_AMOUNT],
           "0x0",
           { from: userB }
         ),
         truffleAssert.ErrorType.revert,
         'ERC1155Tradable#batchMint: ONLY_CREATOR_ALLOWED'
       ));
  });

  describe ('#setBaseMetadataURI()', () => {
    it('should allow the owner to set the base metadata url', async () =>
       truffleAssert.passes(
         instance.setBaseMetadataURI(URI_ROOT, { from: owner })
       ));

    it('should not allow non-owner to set the base metadata url', async () =>
       truffleAssert.fails(
         instance.setBaseMetadataURI(URI_ROOT, { from: userA }),
         truffleAssert.ErrorType.revert,
         'Ownable: caller is not the owner'
       ));
  });

  describe ('#uri()', () => {
    it('should return the correct uri for a token', async () => {
      const tokenId = 1;
      const uri = await instance.uri(tokenId);
      assert.equal(uri, `${URI_ROOT}${tokenId}`);
    });

    it('should not return the uri for a non-existent token', async () =>
       truffleAssert.fails(
         instance.uri(NON_EXISTENT_TOKEN_ID),
         truffleAssert.ErrorType.revert,
         'NONEXISTENT_TOKEN'
       )
      );
  });

  describe('#isApprovedForAll()', () => {
    it('should approve proxy address as _operator', async () => {
      assert.isOk(
        await instance.isApprovedForAll(owner, proxyForOwner)
      );
    });

    it('should not approve non-proxy address as _operator', async () => {
      assert.isNotOk(
        await instance.isApprovedForAll(owner, userB)
      );
    });

    it('should reject proxy as _operator for non-owner _owner', async () => {
      assert.isNotOk(
        await instance.isApprovedForAll(userA, proxyForOwner)
      );
    });

    it('should accept approved _operator for _owner', async () => {
      await instance.setApprovalForAll(userB, true, { from: userA });
      assert.isOk(await instance.isApprovedForAll(userA, userB));
      // Reset it here
      await instance.setApprovalForAll(userB, false, { from: userA });
    });

    it('should not accept non-approved _operator for _owner', async () => {
      await instance.setApprovalForAll(userB, false, { from: userA });
      assert.isNotOk(await instance.isApprovedForAll(userA, userB));
    });
  });
});
