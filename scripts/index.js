const common = require("./common/index.js");
const {
    generateDataCircom,
    generateDataNoir,
    generateInputFileSerialized,
    calculateMsgHash,
} = require("./generateInput.js");
const { generateTree, getInclusionProof } = require("./merkleTree.js");
const { signMessageChunks, signMessageU8 } = require("./signMessage.js");
const { generateProofForContract } = require("./circomGenerateProof.js");

module.exports = {
    generateTree,
    signMessageChunks,
    signMessageU8,
    generateDataCircom,
    generateDataNoir,
    generateInputFileSerialized,
    generateProofForContract,
    calculateMsgHash,
    getInclusionProof,

    common,
};
