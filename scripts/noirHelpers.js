const { stringify } = require("@iarna/toml");
const { writeFile } = require("fs");
const { prepareForSerialization } = require("./common");

function generateProverTOML(inputs) {
    inputs = prepareForSerialization(inputs);
    const tomlString = stringify(inputs);

    writeFile("Prover.toml", tomlString, (err) => {
        if (err) throw err;
        console.log("The Prover file has been saved!");
    });
}

module.exports = {
    generateProverTOML,
};
