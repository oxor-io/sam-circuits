#!/bin/bash

# Error codes:
# 1 - invalid option is provided on the command line.
# 2 - input file with provided name does not exist
# 3 - using the compile option via c witness the file was not provided.

# 100 - invalid option is provided on the command line to compilation script
# 101 - circuit with provided name does not exist
# 102 - circuit compilation failed

# Stop execution if any step returns non-zero (non success) status
set -e


# Errors
ERROR_INVALID_OPTION=1
ERROR_INPUT_FILE_NOT_EXIST=2
ERROR_FILE_NOT_PROVIDED=3


CIRCUIT_NAME=
INPUT_NAME=
TARGET_EXECUTION_METHOD=
WITNESS_GENERATION=false
COMPILATION_REQUIRED=false
SETUP_REQUIRED=false
PROVE_REQUIRED=false
VERIFY_REQUIRED=false


while getopts "n:c:i:wspv" opt; do
  case $opt in
    n)
      CIRCUIT_NAME=$(basename "$OPTARG" .circom)
      ;;
    i)
      INPUT_NAME=$(basename "$OPTARG" .json)
      ;;
    c)
      COMPILATION_REQUIRED=true
      TARGET_EXECUTION_METHOD=$OPTARG
      ;;
    w)
      WITNESS_GENERATION=true
      ;;
    s)
      SETUP_REQUIRED=true
      ;;
    p)
      PROVE_REQUIRED=true
      ;;
    v)
      VERIFY_REQUIRED=true
      ;;
    \?)
      exit $ERROR_INVALID_OPTION
      ;;
  esac
done

BUILD_DIR=build
JS_FOLDER=${BUILD_DIR}/${CIRCUIT_NAME}_js
WITNESS=witness.wtns

POTS_DIR=pots # directory to keep PowersOfTau
POWERTAU=21 # power value for "powersOfTau"

PTAU_FILE=pot${POWERTAU}_0000.ptau
PTAU_PATH=${POTS_DIR}/${PTAU_FILE}

PROOF=${BUILD_DIR}/proof.json
PUBLIC=${BUILD_DIR}/public.json

CONTRIBUTED_PTAU_FILE=contributed_${PTAU_FILE}
FINAL_PTAU=pot${POWERTAU}_final.ptau

# Compile if required
if [ "$COMPILATION_REQUIRED" = true ]; then
  echo "Compilation is required. Start..."

  chmod +x ./shellScripts/compilation.sh
  case "$TARGET_EXECUTION_METHOD" in
    "wasm")
      echo "Compiling to WASM"
      ./shellScripts/compilation.sh -n "${CIRCUIT_NAME}"
      ;;
    "c")
      echo "Compiling to C"
      ./shellScripts/compilation.sh -c -n "${CIRCUIT_NAME}"
      ;;
    *)
      echo "Unknown execution method. Only c or wasm supported!"
      ;;
  esac
fi

if [ "${WITNESS_GENERATION}" == true ]; then
  echo "Generate witness"
  start=$(date +%s)

  if [ ! -f "${INPUT_NAME}".json ]; then
    echo "Input file: ${INPUT_NAME}.json does not exist"
    exit $ERROR_INPUT_FILE_NOT_EXIST
  fi

  case "$TARGET_EXECUTION_METHOD" in
    "wasm")
      node "${JS_FOLDER}"/generate_witness.js "${JS_FOLDER}"/"${CIRCUIT_NAME}".wasm "${INPUT_NAME}".json ${WITNESS}
      mv ${WITNESS} ${BUILD_DIR}
      ;;
    "c")
      printf "\\nUsing {c} to generate witness on Apple Silicon chips is not supported. \\nTo fix this problem, use https://github.com/0xPolygonID/witnesscalc.\\n"
      echo "Generate witness and put *.wtns to build folder"
      read -p "Did you put the *.wtns file in the build folder? (Type Y, if yes): " -r answer

      case "$answer" in
        "Y")
          echo "Ok, moving on..."
          ;;
        "y")
          echo "Ok, moving on..."
          ;;
        "YES")
          echo "Ok, moving on..."
          ;;
        "yes")
          echo "Ok, moving on..."
          ;;
        *)
          echo "You need to generate witness to move on!"
          exit $ERROR_FILE_NOT_PROVIDED
          ;;
      esac
      ;;
    *)
      echo "Unknown execution method. Only c or wasm supported!"
      ;;
  esac
  end=$(date +%s)
  echo "DONE ($((end-start))s)"
fi


if [ -d $POTS_DIR ] && [ -f $PTAU_PATH ] || [ -f "${POTS_DIR}/pot${POWERTAU}_final.ptau" ]; then
  echo "No need to generate new POTS"
else
  echo "Generate new PTAU"
  mkdir -p ${POTS_DIR}
  snarkjs powersoftau new bn128 ${POWERTAU} ${PTAU_PATH}
fi

if [ ! -f "${POTS_DIR}/pot${POWERTAU}_final.ptau" ]; then
  echo "Ceremony required, start..."

  start=$(date +%s)
  snarkjs powersoftau contribute ${PTAU_PATH} ${POTS_DIR}/${CONTRIBUTED_PTAU_FILE} --name="First contribution"
  end=$(date +%s)
  echo "DONE ($((end-start))s)"

  start=$(date +%s)
  snarkjs powersoftau prepare phase2 ${POTS_DIR}/${CONTRIBUTED_PTAU_FILE} ${POTS_DIR}/${FINAL_PTAU}
  end=$(date +%s)
  echo "DONE ($((end-start))s)"
fi

if [ "${SETUP_REQUIRED}" == true ]; then
  start=$(date +%s)
  echo "Setup..."
  snarkjs groth16 setup ${BUILD_DIR}/"${CIRCUIT_NAME}".r1cs ${POTS_DIR}/${FINAL_PTAU} ${BUILD_DIR}/"${CIRCUIT_NAME}"_init.zkey
  end=$(date +%s)
  echo "DONE ($((end-start))s)"

  echo "Contribute to zkey..."
  start=$(date +%s)
  snarkjs zkey contribute ${BUILD_DIR}/"${CIRCUIT_NAME}"_init.zkey ${BUILD_DIR}/"${CIRCUIT_NAME}".zkey --name="1st Contributor Name"
  end=$(date +%s)
  echo "DONE ($((end-start))s)"

  snarkjs zkey export verificationkey ${BUILD_DIR}/"${CIRCUIT_NAME}".zkey ${BUILD_DIR}/verification_key.json
fi

if [ "${PROVE_REQUIRED}" == true ]; then
  echo "Start proving..."
  start=$(date +%s)
  snarkjs groth16 prove ${BUILD_DIR}/"${CIRCUIT_NAME}".zkey ${BUILD_DIR}/${WITNESS} ${PROOF} ${PUBLIC}
  end=$(date +%s)
  echo "DONE ($((end-start))s)"
fi

if [ "${VERIFY_REQUIRED}" == true ]; then
  echo "==============RESULT=============="
  snarkjs groth16 verify ${BUILD_DIR}/verification_key.json ${PUBLIC} ${PROOF}
fi
