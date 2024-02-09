const {
    bigintToUint8Array,
    bigintToArray,
    bigintToArrayBitwise,
    bigintToUint8ArrayBitwise,
    Uint8ArrayToBigint,
    Uint8ArrayToBigintBitwise,
} = require("./bnManipulations");
const { validatePrivKey, validatePubKey, toChecksumAddressIfNot, privKeyToStringAddress } = require("./account");
const { validateMsgHash, prepareForSerialization, bigintArrayToStringArray } = require("./utils");

module.exports = {
    validatePrivKey,
    validatePubKey,
    toChecksumAddressIfNot,
    privKeyToStringAddress,

    bigintToUint8Array,
    bigintToArray,
    Uint8ArrayToBigint,
    bigintToArrayBitwise,
    bigintToUint8ArrayBitwise,
    Uint8ArrayToBigintBitwise,

    validateMsgHash,
    prepareForSerialization,
    bigintArrayToStringArray,
};
