const { MerkleTree } = require("fixed-merkle-tree");
const { buildMimcSponge } = require("circomlibjs");

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

module.exports = { generateTree };
