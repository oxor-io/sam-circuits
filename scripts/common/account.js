const {
    isValidPrivate,
    isValidPublic,
    toBuffer,
    toChecksumAddress,
    isValidChecksumAddress,
    addHexPrefix,
    privateToAddress,
} = require("ethereumjs-util");
const assert = require("assert");

function validatePubKey(pubKey) {
    if (!Buffer.isBuffer(pubKey)) pubKey = toBuffer(pubKey);
    assert(isValidPublic(pubKey), "Invalid public key");
}

function validatePrivKey(privKey) {
    if (!Buffer.isBuffer(privKey)) privKey = toBuffer(privKey);
    assert(isValidPrivate(privKey), "Invalid private key");
}

function privKeyToStringAddress(privKey) {
    assert(privKey instanceof Uint8Array, "Private key must be Uint8Array");
    return addHexPrefix(privateToAddress(toBuffer(privKey)).toString("hex"));
}

function toChecksumAddressIfNot(address) {
    if (!isValidChecksumAddress(address)) {
        address = toChecksumAddress(address);
    }

    return address;
}

module.exports = {
    validatePubKey,
    validatePrivKey,
    toChecksumAddressIfNot,
    privKeyToStringAddress,
};
