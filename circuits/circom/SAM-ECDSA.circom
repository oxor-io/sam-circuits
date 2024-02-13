pragma circom 2.1.2;

include "./ecdsa/ecdsa.circom";
include "./MerkleTree.circom";
include "./zk-identity/eth.circom";

// levels - tree hight
// k registers of n bits each
template SAM(levels, n, k) {
    // Merkle tree
    signal input root;
    signal input pathElements[levels];
    signal input pathIndices[levels];

    // Signature verification
    signal input msgHash[k];
    signal input pubKey[2][k];
    signal input r[k];
    signal input s[k];

    signal output commit;

    // Is msg signed by pubkey? \\
    component SigVerifier = ECDSAVerifyNoPubkeyCheck(n, k);

    SigVerifier.msghash <== msgHash;
    SigVerifier.r <== r;
    SigVerifier.s <== s;
    SigVerifier.pubkey <== pubKey;

    SigVerifier.result === 1;

    // Get address from pubKey \\
    component flattenPubKey = FlattenPubkey(n, k);
    flattenPubKey.chunkedPubkey <== pubKey;

    component getAddressFromPubKey = PubkeyToAddress();
    getAddressFromPubKey.pubkeyBits <== flattenPubKey.pubkeyBits;

    // Hash address to get the leaf
    component addressHasher = MiMCSponge(1, 220, 1);
    addressHasher.ins[0] <== getAddressFromPubKey.address;
    addressHasher.k <== 0;

    // Validate that signer in tree
    component isSignerInTree = MerkleTreeChecker(levels);

    isSignerInTree.leaf <== addressHasher.outs[0];
    isSignerInTree.root <== root;
    isSignerInTree.pathElements <== pathElements;
    isSignerInTree.pathIndices <== pathIndices;

    // Calculate commitment
    component commitHasher = MiMCSponge(k + 1, 220, 1);
    for (var i = 0; i < k + 1; i++) {
        commitHasher.ins[i] <== i == 0 ? getAddressFromPubKey.address : msgHash[i - 1];
    }
    commitHasher.k <== 0;

    commit <== commitHasher.outs[0];
}

component main{ public [root, msgHash] } = SAM(5, 64, 4); // 5 => 32 users