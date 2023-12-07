const {
    validatePrivKey,
    validateMsgHash,
    bigintToArrayBitwise,
    Uint8ArrayToBigintBitwise,
} = require("./common/index.js");
const { isHexString, stripHexPrefix } = require("ethereumjs-util");

// k registers of n bits each
const N = 64n;
const K = 4n;
const ONE_WORD = 256n;

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

    const rAsChunks = bigintToArrayBitwise(N, K, r);
    const sAsChunks = bigintToArrayBitwise(N, K, s);

    const msgHashAsChunks = bigintToArrayBitwise(N, K, Uint8ArrayToBigintBitwise(msgHash));

    const pubKey = secp.ProjectivePoint.fromPrivateKey(privKey);
    const pubKeyXAsChunks = bigintToArrayBitwise(N, K, pubKey.x);
    const pubKeyYAsChunks = bigintToArrayBitwise(N, K, pubKey.y);

    return {
        rAsChunks,
        sAsChunks,
        msgHashAsChunks,
        pubKeyXAsChunks,
        pubKeyYAsChunks,
    };
}

module.exports = { signMessage };
