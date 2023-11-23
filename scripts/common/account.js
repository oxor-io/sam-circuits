const { isValidPrivate, isValidPublic, Address } = require("ethereumjs-util");
const assert = require("assert");

function validateKeyPair(privKey, pubKey) {
  validatePrivKey(privKey);
  validatePubKey(pubKey);
}

function validatePubKey(pubKey) {
  if (!Buffer.isBuffer(pubKey)) pubKey = Buffer.from(pubKey);
  assert(isValidPublic(pubKey), "Invalid public key");
}

function validatePrivKey(privKey) {
  if (!Buffer.isBuffer(privKey)) privKey = Buffer.from(privKey);
  assert(isValidPrivate(privKey), "Invalid private key");
}

function pubKeyToAddressString(pubKey) {
  return Address.fromPublicKey(pubKey).toString();
}

module.exports = {
  pubKeyToAddressString,
  validateKeyPair,
  validatePubKey,
  validatePrivKey,
};
