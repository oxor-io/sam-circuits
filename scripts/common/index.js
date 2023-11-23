const { bigintToUint8Array, bigintToArray, Uint8ArrayToBigint } = require("./bnManipulations");
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

    validateMsgHash,
    createRandomAccount,
    prepareToSerialization,
    bigintArrayToStringArray,
};
