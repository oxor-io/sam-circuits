const { privateToPublic, toChecksumAddress, isValidChecksumAddress } = require("ethereumjs-util");
const { generateTree } = require("./merkleTree.js");
const { signMessage } = require("./signMessage.js");
const { pubKeyToAddressString, validatePrivKey, validatePubKey, prepareToSerialization } = require("./common/index.js");

const fs = require("fs");
const path = require("path");

async function generateInputData(privKey, participantAddresses, msgHash, treeHeight) {
    validatePrivKey(privKey);

    const pubKey = privateToPublic(Buffer.from(privKey));
    validatePubKey(pubKey);

    // We use the custom toChecksumAddressIfNot function because
    // toChecksumAddress can produce an invalid checksum if an address with a correct checksum is passed.
    const currentAddress = toChecksumAddressIfNot(pubKeyToAddressString(pubKey));
    participantAddresses = participantAddresses.map(toChecksumAddressIfNot);

    if (!participantAddresses.includes(currentAddress)) {
        throw new Error("Account with provided private key is not participant of Trie");
    }
    const { tree, treeHashFn } = await generateTree(treeHeight, participantAddresses);
    const currentElement = treeHashFn([currentAddress]);
    const proof = tree.proof(currentElement);

    const { rAsChunks, sAsChunks, msgHashAsChunks, pubKeyXAsChunks, pubKeyYAsChunks } = await signMessage(
        msgHash,
        privKey,
    );

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

function toChecksumAddressIfNot(address) {
    if (!isValidChecksumAddress(address)) {
        address = toChecksumAddress(address);
    }

    return address;
}

module.exports = {
    generateInputData,
    generateInputFileSerialized,
    generateTree,
    signMessage,
};
