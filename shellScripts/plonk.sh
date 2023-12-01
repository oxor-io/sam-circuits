#!/bin/bash

# Stop execution if any step returns non-zero (non-success) status
set -e

echo "START PLONK SETUP"
start=$(date +%s)
node --max-old-space-size=12192 ~/../../usr/local/bin/snarkjs plonk setup build/SAM-ECDSA.r1cs pots/pot23_final.ptau SAM-ECDSA.zkey
end=$(date +%s)
echo "DONE ($((end-start))s)"

echo "START PLONK EXPORT VK"
start=$(date +%s)
snarkjs zkey export verificationkey SAM-ECDSA.zkey verification_key.json
end=$(date +%s)
echo "DONE ($((end-start))s)"

echo "START PLONK PROVE"
start=$(date +%s)
snarkjs plonk prove SAM-ECDSA.zkey build/witness.wtns proof.json public.json
end=$(date +%s)
echo "DONE ($((end-start))s)"

echo "START PLONK VERIFY"
start=$(date +%s)
snarkjs plonk verify verification_key.json public.json proof.json
end=$(date +%s)
echo "DONE ($((end-start))s)"
