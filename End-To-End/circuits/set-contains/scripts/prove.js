#!/usr/bin/env node
import { execSync } from "child_process";
import { buildPoseidon } from "circomlibjs";
import fs from "fs";
import keccak256 from "keccak256";
import path from "path";

// BN128 field prime
const Fp = BigInt(
  "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);

// Initialize poseidon
let poseidon;

// ---------- Helpers ----------
const toField = (hex) => BigInt("0x" + hex) % Fp;

const hashStringToField = (s) => {
  const canon = s.trim().toLowerCase();
  const hex = keccak256(Buffer.from(canon, "utf8")).toString("hex");
  return toField(hex);
};

const poseidon2 = (a, b) => {
  const hash = poseidon([a, b]);
  // poseidon returns a buffer-like array, convert to BigInt
  return poseidon.F.toObject(hash);
};

function nextPow2(n) {
  let p = 1;
  while (p < n) p <<= 1;
  return p;
}

// Build Poseidon-based Merkle tree from leaves
function buildPoseidonMerkle(leaves) {
  // Pad to depth 8 (256 leaves)
  const DEPTH = 8;
  const maxLeaves = 2 ** DEPTH;

  // Pad leaves with zeros to reach 256
  while (leaves.length < maxLeaves) leaves.push(0n);

  const levels = [leaves];

  // Build tree bottom-up for exactly DEPTH levels
  for (let i = 0; i < DEPTH; i++) {
    const currentLevel = levels[i];
    const nextLevel = [];
    for (let j = 0; j < currentLevel.length; j += 2) {
      const left = currentLevel[j];
      const right = currentLevel[j + 1];
      const parent = poseidon2(left, right);
      nextLevel.push(parent);
    }
    levels.push(nextLevel);
  }

  const root = levels[DEPTH][0];
  return { root, levels };
}

// Build Merkle path for index idx
function getPath(levels, idx) {
  const pathElements = [];
  const pathIndex = [];
  let i = idx;

  for (let lvl = 0; lvl < levels.length - 1; lvl++) {
    const isRight = i & 1; // 1 if right child
    const siblingIndex = isRight ? i - 1 : i + 1;

    pathIndex.push(BigInt(isRight));
    pathElements.push(levels[lvl][siblingIndex]);

    i = Math.floor(i / 2);
  }

  // Pad to depth 8 (circuit requirement)
  const DEPTH = 8;
  while (pathElements.length < DEPTH) {
    pathElements.push(0n);
    pathIndex.push(0n);
  }

  return { pathElements, pathIndex };
}

// ---------- Main ----------
function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

const __dirname = path.dirname(new URL(import.meta.url).pathname);

// CLI args
const argv = process.argv.slice(2);
const targetMed =
  (argv.find((a) => a.startsWith("--expected=")) || "").split("=")[1] ||
  "metformin";
const saltStr =
  (argv.find((a) => a.startsWith("--salt=")) || "").split("=")[1] || "12345";
const patientPath =
  (argv.find((a) => a.startsWith("--patient=")) || "").split("=")[1] || null;
const salt = BigInt(saltStr);

// folders
const CIRCUIT_NAME = "SetContains";
const BASE = path.join(__dirname, ".."); // project/circuits/<this>
const BUILD = path.join(BASE, "build"); // build artifacts
const RUNS = path.join(BASE, "runs", targetMed); // proof outputs in medication-specific folder
const WASM = path.join(BUILD, `${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm`);
const GEN_WIT = path.join(BUILD, `${CIRCUIT_NAME}_js/generate_witness.js`);
const ZKEY = path.join(BUILD, `${CIRCUIT_NAME}.zkey`);

// Create runs directory for this medication if it doesn't exist
if (!fs.existsSync(RUNS)) {
  fs.mkdirSync(RUNS, { recursive: true });
}

const INPUT_JSON = path.join(RUNS, "input.json");
const PROOF_JSON = path.join(RUNS, "proof.json");
const PUBLIC_JSON = path.join(RUNS, "public.json");
const VK_JSON = path.join(BUILD, "verification_key.json");
const WITNESS = path.join(RUNS, "witness.wtns");
const CALLDATA = path.join(RUNS, "solidity_calldata.json");

(async () => {
  // Initialize Poseidon hash function
  poseidon = await buildPoseidon();

  // 1) Load your patient JSON
  const patientJsonPath = patientPath
    ? path.resolve(patientPath)
    : path.join(BASE, "patient.json");

  if (!fs.existsSync(patientJsonPath)) {
    throw new Error(`Patient JSON file not found: ${patientJsonPath}`);
  }

  console.log(`📄 Loading patient data from: ${patientJsonPath}`);
  const data = JSON.parse(fs.readFileSync(patientJsonPath, "utf8"));
  assert(
    Array.isArray(data) && data.length > 0,
    "patient.json must be a non-empty array"
  );
  const patient = data[0];

  const meds = (patient.medications || []).map((s) => s.trim().toLowerCase());
  assert(meds.length > 0, "No medications found");

  // 2) Hash each medication to a field element (leaf value)
  const leaves = meds.map(hashStringToField);

  // 3) Build Merkle tree
  const { root, levels } = buildPoseidonMerkle(leaves);

  // 4) Pick expected medication and compute expectedHash (same leaf hashing)
  const expected = targetMed.trim().toLowerCase();
  const expectedHash = hashStringToField(expected);

  // Find its index in the list (must exist in this example)
  const idx = meds.indexOf(expected);
  assert(idx >= 0, `Medication "${expected}" not in patient.medications`);

  const { pathElements, pathIndex } = getPath(levels, idx);

  // 5) Prepare input.json for the circuit
  const input = {
    leaf: leaves[idx].toString(),
    pathElements: pathElements.map((x) => x.toString()),
    pathIndex: pathIndex.map((x) => x.toString()),
    salt: salt.toString(),
    root: root.toString(),
    expectedHash: expectedHash.toString(),
  };

  fs.writeFileSync(INPUT_JSON, JSON.stringify(input, null, 2));
  console.log("🧩 Wrote", INPUT_JSON);

  // 6) Generate witness
  console.log("⚙️  Generating witness...");
  execSync(`node ${GEN_WIT} ${WASM} ${INPUT_JSON} ${WITNESS}`, {
    stdio: "inherit",
  });

  // 7) Prove
  console.log("🔐 Generating Groth16 proof...");
  execSync(
    `npx snarkjs groth16 prove ${ZKEY} ${WITNESS} ${PROOF_JSON} ${PUBLIC_JSON}`,
    { stdio: "inherit" }
  );

  // 8) Verify locally
  console.log("✅ Verifying proof locally...");
  execSync(
    `npx snarkjs groth16 verify ${VK_JSON} ${PUBLIC_JSON} ${PROOF_JSON}`,
    { stdio: "inherit" }
  );

  // 9) Export solidity calldata as JSON
  console.log("🧾 Exporting solidity calldata...");
  const proof = JSON.parse(fs.readFileSync(PROOF_JSON, "utf8"));
  const publicSignals = JSON.parse(fs.readFileSync(PUBLIC_JSON, "utf8"));

  // Parse the proof into the format expected by Solidity verifier
  const calldata = {
    proof: {
      pi_a: [proof.pi_a[0], proof.pi_a[1]],
      pi_b: [
        [proof.pi_b[0][1], proof.pi_b[0][0]],
        [proof.pi_b[1][1], proof.pi_b[1][0]],
      ],
      pi_c: [proof.pi_c[0], proof.pi_c[1]],
    },
    publicSignals: publicSignals,
  };

  fs.writeFileSync(CALLDATA, JSON.stringify(calldata, null, 2));
  console.log("🧾 Wrote", CALLDATA);

  console.log(
    "🎉 Done. Public signals (root, expectedHash, commitment, ok) are in",
    PUBLIC_JSON
  );
})();
