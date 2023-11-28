const { privateToPublic } = require("ethereumjs-util");
const { generateTree } = require("./merkleTree.js");
const { signMessage } = require("./signMessage.js");
const { pubKeyToAddressString, validatePrivKey, validatePubKey, prepareToSerialization } = require("./common/index.js");

const fs = require("fs");
const path = require("path");

async function generateInputData(privKey, participantAddresses, msgHash, treeHeight) {
    validatePrivKey(privKey);

    const pubKey = privateToPublic(Buffer.from(privKey));
    validatePubKey(pubKey);

    const { rAsChunks, sAsChunks, msgHashAsChunks, pubKeyXAsChunks, pubKeyYAsChunks } = await signMessage(
        msgHash,
        privKey,
    );

    const currentAddress = pubKeyToAddressString(pubKey);
    if (participantAddresses.indexOf(currentAddress) === -1) {
        throw new Error("Account with provided private key is not participant of Trie");
    }

    const { tree, treeHashFn } = await generateTree(treeHeight, participantAddresses);

    const currentElement = treeHashFn([currentAddress]);
    const proof = tree.proof(currentElement);

    const witness = {
        root: tree.root.toString(),

        pathElements: proof.pathElements,
        pathIndices: proof.pathIndices,

        msgHash: msgHashAsChunks,
        pubKey: [pubKeyXAsChunks, pubKeyYAsChunks],
        r: rAsChunks,
        s: sAsChunks,
    };

    return witness;
}

async function generateInputFileSerialized(privKey, participantAddresses, msgHash, treeHeight) {
    const witness = generateInputData(privKey, participantAddresses, msgHash, treeHeight);
    prepareToSerialization(witness);

    const outputPath = path.join(__dirname, "..", "input.json");
    fs.writeFileSync(outputPath, JSON.stringify(witness), "utf-8");
}

module.exports = {
    generateInputData,
    generateInputFileSerialized,
    generateTree,
    signMessage,
};
