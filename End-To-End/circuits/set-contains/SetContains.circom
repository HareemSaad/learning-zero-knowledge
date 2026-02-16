pragma circom 2.1.6;

include "../circomlib/circuits/poseidon.circom";
include "../circomlib/circuits/comparators.circom";

// Verifies that a given leaf is part of a Merkle root and equals expectedHash.
// Uses Poseidon(2) for hashing and avoids non-quadratic constraints.
template SetContains(depth) {
    // ========== PRIVATE INPUTS ==========
    signal input leaf;                // hash(item)
    signal input pathElements[depth]; // sibling nodes
    signal input pathIndex[depth];    // 0 if left, 1 if right
    signal input salt;                // randomizer

    // ========== PUBLIC INPUTS ==========
    signal input root;                // Merkle root
    signal input expectedHash;        // hash(expected item)

    // ========== PUBLIC OUTPUTS ==========
    signal output commitment;         // Poseidon(root, salt)
    signal output expectedHashOut;    // echo expectedHash for verification
    signal output ok;                 // must be 1

    // --- Verify leaf == expectedHash ---
    component eq = IsEqual();
    eq.in[0] <== leaf;
    eq.in[1] <== expectedHash;
    ok <== eq.out;
    ok === 1;

    // Echo expectedHash as output for on-chain verification
    expectedHashOut <== expectedHash;

    // --- Merkle proof verification ---
    component hashers[depth];
    signal left[depth];
    signal right[depth];
    signal cur[depth + 1]; // state progression signals

    cur[0] <== leaf; // initialize first node

    for (var i = 0; i < depth; i++) {
        // Ensure pathIndex[i] is boolean
        pathIndex[i] * (1 - pathIndex[i]) === 0;

        hashers[i] = Poseidon(2);

        // Conditional selection (linear-safe)
        left[i] <== cur[i] + (pathElements[i] - cur[i]) * pathIndex[i];
        right[i] <== pathElements[i] + (cur[i] - pathElements[i]) * pathIndex[i];

        hashers[i].inputs[0] <== left[i];
        hashers[i].inputs[1] <== right[i];
        cur[i + 1] <== hashers[i].out; // next node in path
    }

    // Final root check
    cur[depth] === root;

    // --- Commitment for anti-replay ---
    component bind = Poseidon(2);
    bind.inputs[0] <== root;
    bind.inputs[1] <== salt;
    commitment <== bind.out;
}

component main = SetContains(8);
