#!/bin/bash
set -e

# ========== CONFIG ==========
CIRCUIT_NAME="SetContains"
BUILD_DIR="./build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTRACT_DIR="${SCRIPT_DIR}/../../contracts/src/verifiers"
CONTRACT_NAME="SetContains.sol"
PTAU_FILE="${BUILD_DIR}/pot12_final_prepared.ptau"
CURVE="bn128"
POWERS=15

# ========== CLEANUP ==========
echo "[1/10] Cleaning old build..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $CONTRACT_DIR

# ========== COMPILE CIRCUIT ==========
echo "[2/10] Compiling circuit..."
circom ${CIRCUIT_NAME}.circom --r1cs --wasm --sym -o $BUILD_DIR

echo "[INFO] R1CS info:"
snarkjs r1cs info ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs

# ========== SETUP POWERS OF TAU ==========
if [ ! -f $PTAU_FILE ]; then
  echo "[3/10] Generating new powers of tau..."
  npx snarkjs powersoftau new $CURVE $POWERS ${BUILD_DIR}/pot${POWERS}_0000.ptau -v
  npx snarkjs powersoftau contribute ${BUILD_DIR}/pot${POWERS}_0000.ptau ${BUILD_DIR}/pot${POWERS}_contrib.ptau \
    --name="First contribution" -v
  npx snarkjs powersoftau prepare phase2 ${BUILD_DIR}/pot${POWERS}_contrib.ptau $PTAU_FILE -v
else
  echo "[3/10] Using existing $PTAU_FILE"
fi


# ========== GROTH16 SETUP ==========
echo "[4/10] Running Groth16 setup..."
npx snarkjs groth16 setup ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs $PTAU_FILE ${BUILD_DIR}/${CIRCUIT_NAME}.zkey -v

echo "[INFO] Zkey size:"
ls -lh ${BUILD_DIR}/${CIRCUIT_NAME}.zkey

# ========== EXPORT VERIFICATION KEY ==========
echo "[5/10] Exporting verification key..."
npx snarkjs zkey export verificationkey ${BUILD_DIR}/${CIRCUIT_NAME}.zkey ${BUILD_DIR}/verification_key.json

# ========== EXPORT SOLIDITY VERIFIER ==========
echo "[10/10] Exporting Solidity verifier..."
npx snarkjs zkey export solidityverifier ${BUILD_DIR}/${CIRCUIT_NAME}.zkey ${CONTRACT_DIR}/${CONTRACT_NAME}

echo "✅ Done! Files generated in $BUILD_DIR:"
ls -lh $BUILD_DIR
echo "Verifier exported to: ${CONTRACT_DIR}/${CONTRACT_NAME}"
