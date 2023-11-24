#!/bin/bash

# Stop execution if any step returns non-zero (non-success) status
set -e

# Errors
ERROR_INVALID_OPTION=100
ERROR_NO_CIRCUIT=101
ERROR_COMPILATION_FAILED=102


TARGET_EXECUTION_METHOD="--wasm"
CIRCUIT_NAME=
BUILD_DIR=build

while getopts "n:c" opt; do
  case ${opt} in
    n)
      CIRCUIT_NAME=$(basename "$OPTARG" .circom)
      ;;
    c)
      TARGET_EXECUTION_METHOD="-c"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit $ERROR_INVALID_OPTION
      ;;
  esac
done

# Check if the circuit exists
if [ ! -f circuits/"${CIRCUIT_NAME}".circom ]; then
  echo "circuits/${CIRCUIT_NAME}.circom doesn't exist, exit..."
  exit $ERROR_NO_CIRCUIT
fi

if [ -d "$BUILD_DIR" ]; then
  echo "$BUILD_DIR exists, deleting..."
  rm -rf ./$BUILD_DIR
fi

echo "Creating new $BUILD_DIR directory"
mkdir -p "$BUILD_DIR"

echo "Building R1CS for circuit ${CIRCUIT_NAME}.circom"
start=$(date +%s)
if ! circom circuits/"${CIRCUIT_NAME}".circom --r1cs $TARGET_EXECUTION_METHOD --sym -o $BUILD_DIR; then
  echo "circuits/${CIRCUIT_NAME}.circom compilation to r1cs failed. Exiting..."
  exit $ERROR_COMPILATION_FAILED
fi
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "Info about circuits/${CIRCUIT_NAME}.circom R1CS constraints system"
snarkjs info -c ${BUILD_DIR}/"${CIRCUIT_NAME}".r1cs
