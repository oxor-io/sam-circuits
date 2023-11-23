const { validatePrivKey, bigintToArray, validateMsgHash, Uint8ArrayToBigint } = require("./common/index.js");

const { isHexString, stripHexPrefix } = require("ethereumjs-util");

// k registers of n bits each
const N = 64;
const K = 4;
const ONE_WORD = 256;

/**
 * @param {String} msgHash - msg to be signed as hex
 * @param {Uint8Array} privKey - Private key to sign the message
 * @returns {Object} { rAsChunks, sAsChunks, msgHashAsChunks, pubKeyXAsChunks, pubKeyYAsChunks } - witness
 */
async function signMessage(msgHash, privKey, params = { N, K }) {
    const { N, K } = params;

    if (N * K !== ONE_WORD) {
        throw new Error("N * K must be 256 (32 bytes)");
    }

    validateMsgHash(msgHash);
    validatePrivKey(privKey);

    const secp = await import("@noble/secp256k1");

    // After this block msgHash is Uint8Array
    if (isHexString(msgHash) || isHexString("0x" + msgHash)) {
        const msgHashWithoutPrefix = stripHexPrefix(msgHash);
        msgHash = secp.etc.hexToBytes(msgHashWithoutPrefix);
    }

    const { r, s } = await secp.signAsync(msgHash, privKey);

    const rAsChunks = bigintToArray(N, K, r);
    const sAsChunks = bigintToArray(N, K, s);

    const msgHashAsChunks = bigintToArray(N, K, Uint8ArrayToBigint(msgHash));

    const pubKey = secp.ProjectivePoint.fromPrivateKey(privKey);
    const pubKeyXAsChunks = bigintToArray(N, K, pubKey.x);
    const pubKeyYAsChunks = bigintToArray(N, K, pubKey.y);

    return {
        rAsChunks,
        sAsChunks,
        msgHashAsChunks,
        pubKeyXAsChunks,
        pubKeyYAsChunks,
    };
}

module.exports = { signMessage };
