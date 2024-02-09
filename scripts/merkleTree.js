const { MerkleTree } = require("fixed-merkle-tree");
const { buildMimcSponge } = require("circomlibjs");
const { toChecksumAddressIfNot } = require("./common/account");

async function generateTree(levels, leafData, keyForMimc = 0n) {
    const mimcSponge = await buildMimcSponge();

    function mimcMultiHash(values) {
        if (!Array.isArray(values)) {
            throw new Error("Values must be an array type");
        }

        const res = mimcSponge.multiHash(values, keyForMimc);
        return mimcSponge.F.toObject(res);
    }

    const leaves = leafData.map((val) => mimcMultiHash([val]));
    const tree = new MerkleTree(levels, leaves, {
        hashFunction: (l, r) => mimcMultiHash([l, r]),
    });

    return { tree, treeHashFn: mimcMultiHash };
}

async function getInclusionProof(userAddress, participantAddresses, treeHeight) {
    // We use the custom toChecksumAddressIfNot function because
    // toChecksumAddress can produce an invalid checksum if an address with a correct checksum was passed.
    userAddress = toChecksumAddressIfNot(userAddress);
    participantAddresses = participantAddresses.map(toChecksumAddressIfNot);

    if (!participantAddresses.includes(userAddress)) {
        throw new Error("Account with provided private key is not participant of Trie");
    }

    const { tree, treeHashFn } = await generateTree(treeHeight, participantAddresses);
    const currentElement = treeHashFn([userAddress]);

    return { proof: tree.proof(currentElement), tree };
}

module.exports = { generateTree, getInclusionProof };
