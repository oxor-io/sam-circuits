const { stringify } = require("@iarna/toml");
const { writeFile } = require("fs");
const { prepareForSerialization } = require("./common");
const { join, resolve } = require("path");
const os = require("os");

const { compile, createFileManager } = require("@noir-lang/noir_wasm");
const { BarretenbergBackend } = require("@noir-lang/backend_barretenberg");
const { Noir } = require("@noir-lang/noir_js");

function generateProverTOML(inputs) {
    inputs = prepareForSerialization(inputs);
    const tomlString = stringify(inputs);

    writeFile("Prover.toml", tomlString, (err) => {
        if (err) throw err;
        console.log("The Prover file has been saved!");
    });
}

async function getCircuit(name) {
    const basePath = resolve(join("circuits-noir", name));
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

async function getNoirComponents(circuitName, options = { threads: os.availableParallelism() }) {
    const circuit = await getCircuit(circuitName);
    const backend = getBackend(circuit, options.threads);
    const noir = getNoir(circuit, backend);

    return {
        circuit,
        backend,
        noir,
    };
}

module.exports = {
    generateProverTOML,
    getCircuit,
    getBackend,
    getNoirComponents,
};
