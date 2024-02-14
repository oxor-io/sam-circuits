const { stringify: tomlStringify } = require("@iarna/toml");
const { writeFile } = require("fs");
const { prepareForSerialization } = require("./common");
const os = require("os");

const { compile, createFileManager } = require("@noir-lang/noir_wasm");
const { BarretenbergBackend } = require("@noir-lang/backend_barretenberg");
const { Noir } = require("@noir-lang/noir_js");

function writeProverTOML(inputs, writeTo) {
    inputs = prepareForSerialization(inputs);
    const tomlString = tomlStringify(inputs);

    writeFile(writeTo, tomlString, (err) => {
        if (err) throw err;
        console.log("The Prover file has been saved!");
    });
}

async function getCircuit(basePath) {
    const fm = createFileManager(basePath);
    const compiled = await compile(fm, basePath);
    if (!("program" in compiled)) {
        throw new Error("Compilation failed");
    }
    return compiled.program;
}

function getBackend(program, threads) {
    return new BarretenbergBackend(program, { threads });
}

function getNoir(circuit, backend) {
    return new Noir(circuit, backend);
}

async function getNoirComponents(basePath, options = { threads: os.availableParallelism() }) {
    const circuit = await getCircuit(basePath);
    const backend = getBackend(circuit, options.threads);
    const noir = getNoir(circuit, backend);

    return {
        circuit,
        backend,
        noir,
    };
}

module.exports = {
    writeProverTOML,
    getCircuit,
    getBackend,
    getNoirComponents,
};
