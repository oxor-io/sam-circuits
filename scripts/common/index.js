const {
    bigintToUint8Array,
    bigintToArray,
    bigintToArrayBitwise,
    bigintToUint8ArrayBitwise,
    Uint8ArrayToBigint,
    Uint8ArrayToBigintBitwise,
} = require("./bnManipulations");
const { validateKeyPair, validatePrivKey, validatePubKey, pubKeyToAddressString } = require("./account");
const { validateMsgHash, createRandomAccount, prepareToSerialization, bigintArrayToStringArray } = require("./utils");

module.exports = {
    validateKeyPair,
    validatePrivKey,
    validatePubKey,
    pubKeyToAddressString,

    bigintToUint8Array,
    bigintToArray,
    Uint8ArrayToBigint,
    bigintToArrayBitwise,
    bigintToUint8ArrayBitwise,
    Uint8ArrayToBigintBitwise,

    validateMsgHash,
    createRandomAccount,
    prepareToSerialization,
    bigintArrayToStringArray,
};
