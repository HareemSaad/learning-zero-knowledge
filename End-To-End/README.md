1. Navigate to the `End-To-End` directory:

```bash
cd End-To-End
npm install
```

2. Compile the circuit

Builds the zero-knowledge circuit from scratch — compiles Circom, runs Groth16 setup, generates a sample proof, verifies it locally, and exports a ready-to-deploy Solidity verifier (Verifier.sol).

Generated smart contract verifier's can be found in `contracts/src/verifiers/`.

```bash
npm run compile-set-contains
```

3. Generate a proof:

```bash
    npm run prove-set-contains -- --target <item_to_check> --salt <random_salt> [--patient <path_to_patient_json>]
    # npm run prove-set-contains -- --target metformin --salt 5656 -- ./set-contains/patient.json
```

This will generate a proof that the item is in the set without revealing the actual item. The proof will be saved in `set_contains/runs/target-salt/`.
Note: If the item is not in the set, the witness generation will fail, and an error message will be displayed.

4. Test the proof on contracts:

```bash
forge test
```

This will run the tests in `contracts/test/` which include tests for the generated proof. The tests will verify that the proof is valid and that the verifier contract works as expected.