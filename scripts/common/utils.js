const { isHexString, privateToPublic } = require("ethereumjs-util");

function validateMsgHash(msgHash) {
    const isHex = isHexString(msgHash) || isHexString("0x" + msgHash);

    if (!isHex && !(msgHash instanceof Uint8Array)) {
        throw new Error("MsgHash must be hex string or Uint8Array");
    }
}

async function createRandomAccount() {
    const privKey = (await import("@noble/secp256k1")).utils.randomPrivateKey();
    const pubKey = privateToPublic(Buffer.from(privKey));

    return {
        privKey,
        pubKey,
    };
}

function prepareToSerialization(witnessObj) {
    for (const key in witnessObj) {
        // Currently all array variables are bigint
        if (Array.isArray(witnessObj[key])) {
            // Because some arrays are nested - we use recursion
            witnessObj[key] = bigintArrayToStringArray(witnessObj[key]);
        }
    }
}

function bigintArrayToStringArray(x) {
    if (!Array.isArray(x)) return x.toString();
    else return x.map(bigintArrayToStringArray);
}

module.exports = {
    validateMsgHash,
    createRandomAccount,
    prepareToSerialization,
    bigintArrayToStringArray,
};
