const { generateProofForContract } = require("./circomGenerateProof.js");
const { calculateMsgHash, generateDataCircom, generateDataNoir } = require("./generateInput");
const { bigintToUint8ArrayBitwise } = require("./common/bnManipulations");

const { ANVIL_ADDRESSES, ANVIL_PRIVATE_KEYS } = require("./common/anvil_accounts_data.json");
const { writeProverTOML } = require("./noirHelpers.js");
const { resolve } = require("path");

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

const IS_FOR_CIRCOM = false;

(async function () {
    const msgHash = calculateMsgHash(TO, VALUE, DATA, OPERATION, NONCE, SAM_ADDRESS, CHAIN_ID);
    let data;

    const privKeyU8Arr = bigintToUint8ArrayBitwise(BigInt(ANVIL_PRIVATE_KEYS[0]));

    if (IS_FOR_CIRCOM) {
        data = await generateDataCircom(privKeyU8Arr, ANVIL_ADDRESSES, msgHash, TREE_HIGHT);
        console.log(data);

        const wasmPath = BUILD_PATH + CIRCUIT_NAME + "_js/" + CIRCUIT_NAME + ".wasm";
        const zkeyPath = BUILD_PATH + CIRCUIT_NAME + ".zkey";

        await generateProofForContract(data, wasmPath, zkeyPath, { outputType: "console" });
    } else {
        data = await generateDataNoir(privKeyU8Arr, ANVIL_ADDRESSES, msgHash, TREE_HIGHT);
        const pathToWrite = resolve("./circuits/noir/main/Prover.toml");
        writeProverTOML(data, pathToWrite);
    }
})();
