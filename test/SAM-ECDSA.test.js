const { generateDataCircom } = require("../scripts/index");
const { bigintToUint8ArrayBitwise } = require("../scripts/common/index");
const { ANVIL_ADDRESSES, ANVIL_PRIVATE_KEYS } = require("../scripts/common/anvil_accounts_data.json");

const wasmTester = require("circom_tester/index").wasm;
const path = require("path");

const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);
const { expect } = chai;

// Constants
const CIRCUIT_FILE_NAME = "SAM-ECDSA.circom";
const CIRCUIT_FILE_PATH = path.join(__dirname, "../circuits", CIRCUIT_FILE_NAME);
const OUTPUT = path.join(__dirname, "../build");

const TREE_HIGHT = 5;
const DEFAULT_MSG_HASH = "0x104ffbad9450b48089e3d917b63fc13c88ddac7ed4a02bc03512d883f0666c8b";

describe("SAM circuit", function () {
    this.timeout(1000000);

    let circuit, defaultWitnessData;
    let defaultUserPrivateKey;

    before(async () => {
        defaultUserPrivateKey = bigintToUint8ArrayBitwise(BigInt(ANVIL_PRIVATE_KEYS[0]));
        defaultWitnessData = await generateDataCircom(
            defaultUserPrivateKey,
            ANVIL_ADDRESSES,
            DEFAULT_MSG_HASH,
            TREE_HIGHT,
        );

        try {
            circuit = await wasmTester(CIRCUIT_FILE_PATH, { output: OUTPUT, recompile: false });
            console.log("Compiled version detected...");
        } catch (e) {
            console.log("Compiled version has not been detected... Compile");
            const PATH_DOES_NOT_EXISTS_ERR_MSG = "Cannot set recompile to false if";

            if (e.message.includes(PATH_DOES_NOT_EXISTS_ERR_MSG)) {
                circuit = await wasmTester(CIRCUIT_FILE_PATH);
            }
        }
    });

    it("Circuit can be verified with valid witness (full tree)", async function () {
        const witness = await circuit.calculateWitness(defaultWitnessData);
        await circuit.checkConstraints(witness);
    });

    it("Circuit can be verified with valid witness (tree with empty leafs)", async function () {
        const witnessData = await generateDataCircom(
            defaultUserPrivateKey,
            ANVIL_ADDRESSES.slice(0, 10),
            DEFAULT_MSG_HASH,
            TREE_HIGHT,
        );
        const witness = await circuit.calculateWitness(witnessData);
        await circuit.checkConstraints(witness);
    });

    it("Circuit can't be verified with invalid root", async function () {
        const witnessData = Object.assign({}, defaultWitnessData);

        // Make root invalid
        for (let i = 0; i < 9; i++) {
            if (witnessData.root.includes(i + "")) {
                witnessData.root = witnessData.root.replace(i + "", ((i + 1) % 10) + "");
                break;
            }
        }

        expect(circuit.calculateWitness(witnessData)).to.eventually.rejected;
    });

    it("Circuit can't be verified with invalid pathIndices", async function () {
        const witnessData = Object.assign({}, defaultWitnessData);

        // Make path invalid
        witnessData.pathIndices[0] = Number(!witnessData.pathIndices[0]);
        expect(circuit.calculateWitness(witnessData)).to.eventually.rejected;
    });
});
