#!/bin/bash

# Stop execution if any step returns non-zero (non success) status
set -e


if [ -z "$1" ]; then
    echo "Incorrect usage. Provide as 1st argument name of the .zkey file to be imported as verifier."
    exit 1
fi

VERIFIER_DIR="src"
if [ -z "$2" ]; then
    echo "Path to save verifier is not provided..."
else
    VERIFIER_DIR=$2
fi
echo "Saving to: "${VERIFIER_DIR}

mkdir -p $VERIFIER_DIR

ZKEY_NAME=$(basename "$1" .zkey)
snarkjs zkey export solidityverifier ./build/$ZKEY_NAME.zkey "${VERIFIER_DIR}"/Verifier.sol