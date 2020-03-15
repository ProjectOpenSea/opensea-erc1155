module.exports = async function(promise, errorMessageSearch = null) {
    try {
        await promise;
    } catch (error) {
        if (errorMessageSearch) {
            assert(
                error.message.search(errorMessageSearch) >= 0,
                'Expected specific error message ' + errorMessageSearch + ', received:' + error
            );
            return;
        }

        let invalidOpcode = error.message.search('invalid opcode') >= 0;
        let outOfGas = error.message.search('out of gas') >= 0;
        let revert = error.message.search('revert') >= 0;

        assert(invalidOpcode || outOfGas || revert, 'Unexpected thrown error: \'' + error);
        return;
    }

    assert.fail('Expected throw not received');
};
