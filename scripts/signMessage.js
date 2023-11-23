const {
  validatePrivKey,
  bigint_to_array,
  validateMsgHash,
  Uint8Array_to_bigint,
} = require("./common/index.js");

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
async function signMessage(msgHash, privKey, params = { N: N, K: K }) {
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

  const rAsChunks = bigint_to_array(N, K, r);
  const sAsChunks = bigint_to_array(N, K, s);

  const msgHashAsChunks = bigint_to_array(N, K, Uint8Array_to_bigint(msgHash));

  const pubKey = secp.ProjectivePoint.fromPrivateKey(privKey);
  const pubKeyXAsChunks = bigint_to_array(N, K, pubKey.x);
  const pubKeyYAsChunks = bigint_to_array(N, K, pubKey.y);

  return {
    rAsChunks,
    sAsChunks,
    msgHashAsChunks,
    pubKeyXAsChunks,
    pubKeyYAsChunks,
  };
}

module.exports = { signMessage };
