const { generateInputData } = require("../scripts/index");
const { createRandomAccount, pubKeyToAddressString } = require("../scripts/common/index");

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
const DEFAULT_MSG_HASH = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6";

// Helper function
async function createArrayOfAccounts(size) {
    const arr = new Array(size).fill(undefined);
    return Promise.all(arr.map(() => createRandomAccount()));
}

describe("SAM circuit", function () {
    this.timeout(1000000);

    let accounts, mainAccount, accountAddresses;
    let circuit, defaultWitnessData;

    before(async () => {
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

        accounts = await createArrayOfAccounts(2 ** TREE_HIGHT);
        [mainAccount] = accounts;

        accountAddresses = accounts.map((acc) => pubKeyToAddressString(Buffer.from(acc.pubKey)));
        defaultWitnessData = await generateInputData(
            mainAccount.privKey,
            accountAddresses,
            DEFAULT_MSG_HASH,
            TREE_HIGHT,
        );
    });

    it("Circuit can be verified with valid witness", async function () {
        const witness = await circuit.calculateWitness(defaultWitnessData);
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
