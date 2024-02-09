const { groth16 } = require("snarkjs");

const fs = require("fs");
const path = require("path");

async function generateProofForContract(
    inputSignals,
    wasmFile,
    zkeyFileName,
    options = { inputPath: null, outputType: null, outputPath: null },
) {
    if (options.inputPath) {
        const inputPath = path.join(__dirname, options.inputPath);
        inputSignals = JSON.parse(fs.readFileSync(inputPath));
    }

    wasmFile = path.isAbsolute(wasmFile) ? wasmFile : path.join(__dirname, wasmFile);
    zkeyFileName = path.isAbsolute(zkeyFileName) ? zkeyFileName : path.join(__dirname, zkeyFileName);

    const { proof, publicSignals } = await groth16.fullProve(inputSignals, wasmFile, zkeyFileName);
    const calldataStr = await groth16.exportSolidityCallData(proof, [publicSignals[0]]);

    if (options.outputType === "console") {
        console.log(calldataStr);
    } else if (options.outputType === "file") {
        if (!options.outputPath) throw new Error("Output path is empty");
        fs.writeFileSync(options.outputPath, calldataStr);
    }

    return JSON.parse("[" + calldataStr + "]");
}

module.exports = {
    generateProofForContract,
};
