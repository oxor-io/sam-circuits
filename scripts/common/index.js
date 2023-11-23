const {
  bigint_to_Uint8Array,
  bigint_to_array,
  Uint8Array_to_bigint,
} = require("./bnManipulations");

const {
  validateKeyPair,
  validatePrivKey,
  validatePubKey,
  pubKeyToAddressString,
} = require("./account");

const {
  validateMsgHash,
  createRandomAccount,
  prepareToSerialization,
  bigintArrayToStringArray,
} = require("./utils");

module.exports = {
  validateKeyPair,
  validatePrivKey,
  validatePubKey,
  pubKeyToAddressString,

  bigint_to_Uint8Array,
  bigint_to_array,
  Uint8Array_to_bigint,

  validateMsgHash,
  createRandomAccount,
  prepareToSerialization,
  bigintArrayToStringArray,
};
