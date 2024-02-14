const { getInclusionProof } = require("./merkleTree.js");
const { signMessageChunks, signMessageU8 } = require("./signMessage.js");
const { keccak256 } = require("@ethersproject/solidity");
const { defaultAbiCoder } = require("@ethersproject/abi");
const { prepareForSerialization, privKeyToStringAddress } = require("./common/index.js");

async function generateDataCircom(privKey, participantAddresses, msgHash, treeHeight) {
    const { rAsChunks, sAsChunks, msgHashAsChunks, pubKeyXAsChunks, pubKeyYAsChunks } = await signMessageChunks(
        msgHash,
        privKey,
    );

    const currentAddress = privKeyToStringAddress(privKey);
    const { proof, tree } = await getInclusionProof(currentAddress, participantAddresses, treeHeight);

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

async function generateDataNoir(privKey, participantAddresses, msgHash, treeHeight) {
    const { msgHash: msgHashU8, sigBytes, pubKey } = await signMessageU8(msgHash, privKey);

    const currentAddress = privKeyToStringAddress(privKey);
    const { proof, tree } = await getInclusionProof(currentAddress, participantAddresses, treeHeight);

    proof.pathIndices = compressPositions(proof.pathIndices);

    const witness = {
        root: tree.root.toString(),

        hash_path: proof.pathElements,
        path_indexes: proof.pathIndices,

        msg_hash: { arr: msgHashU8 },
        pub_key: pubKey,
        sig: sigBytes,
    };

    return witness;
}

// If options.order == false => reverse position array
function compressPositions(positions_indexes, options = { order: true }) {
    if (!options.order) {
        positions_indexes = positions_indexes.reverse();
    }

    let result = 0;
    for (let i = positions_indexes.length - 1; i >= 0; i--) {
        if ((positions_indexes[i] & 1) != positions_indexes[i]) {
            throw new Error("Not a bin index");
        }

        const inverseIndex = positions_indexes.length - 1 - i;
        const num = positions_indexes[i] << inverseIndex;

        result |= num;
    }

    return result;
}

async function generateInputFileSerialized(privKey, participantAddresses, msgHash, treeHeight) {
    const fs = require("fs");
    const path = require("path");

    const witness = generateInputData(privKey, participantAddresses, msgHash, treeHeight);
    prepareForSerialization(witness);

    const outputPath = path.join(__dirname, "..", "input.json");
    fs.writeFileSync(outputPath, JSON.stringify(witness), "utf-8");
}

function calculateMsgHash(to, value, data, operation, nonce, samAddress, chainId) {
    const calldataHash = keccak256(["bytes"], [data]);

    const encodedData = defaultAbiCoder.encode(
        ["address", "uint256", "bytes32", "uint8", "uint256", "address", "uint256"],
        [to, value, calldataHash, operation, nonce, samAddress, chainId],
    );
    const msgHash = keccak256(["bytes"], [encodedData]);

    return msgHash;
}

module.exports = {
    generateDataCircom,
    generateDataNoir,
    generateInputFileSerialized,
    calculateMsgHash,
};
