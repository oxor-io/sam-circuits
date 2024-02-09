const { generateProofForContract } = require("./circomGenerateProof.js");
const { calculateMsgHash, generateDataCircom } = require("./generateInput");
const { bigintToUint8ArrayBitwise } = require("./common/bnManipulations");

const { ANVIL_ADDRESSES, ANVIL_PRIVATE_KEYS } = require("./common/anvil_accounts_data.json");

const TO = "0x43B19cc4207cedCa14bF3F83e7a5f8F9EaeDaA8c";
const VALUE = 0;
const DATA = "0xe75235b8"; // getThreshold
const OPERATION = 0; // CALL
const NONCE = 0;
const SAM_ADDRESS = "0x43B19cc4207cedCa14bF3F83e7a5f8F9EaeDaA8c";
const CHAIN_ID = 1;

const TREE_HIGHT = 5;
const BUILD_PATH = "../build/";
const CIRCUIT_NAME = "SAM-ECDSA";

(async function () {
    const msgHash = calculateMsgHash(TO, VALUE, DATA, OPERATION, NONCE, SAM_ADDRESS, CHAIN_ID);

    const data = await generateDataCircom(
        bigintToUint8ArrayBitwise(BigInt(ANVIL_PRIVATE_KEYS[0])),
        ANVIL_ADDRESSES,
        msgHash,
        TREE_HIGHT,
    );
    console.log(data);

    const wasmPath = BUILD_PATH + CIRCUIT_NAME + "_js/" + CIRCUIT_NAME + ".wasm";
    const zkeyPath = BUILD_PATH + CIRCUIT_NAME + ".zkey";

    await generateProofForContract(data, wasmPath, zkeyPath, { outputType: "console" });
})();
