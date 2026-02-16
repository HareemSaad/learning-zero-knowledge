// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./../IVerifierAdapter.sol";
import "./../IGroth16Verifier.sol";

contract SetContainsAdapter is IVerifierAdapter {
    error ZeroAddress();
    error InvalidConstrain();
    error InvalidArrayLength();
    error ValueMismatch();
    error ProofFailed();

    IGroth16Verifier public immutable verifier;
    uint256 public immutable expectedMedicationHash; // hash of the specific medication to verify
    bytes32 public immutable override zKeyHash;

    constructor(
        address _verifier,
        uint256 _expectedMedicationHash,
        bytes32 _zKeyHash
    ) {
        if (_verifier == address(0)) revert ZeroAddress();
        if (_expectedMedicationHash == 0) revert InvalidConstrain();
        verifier = IGroth16Verifier(_verifier);
        expectedMedicationHash = _expectedMedicationHash;
        zKeyHash = _zKeyHash;
    }

    /// proof is abi.encode(a, b, c)
    /// publicInputs = [commitment, expectedHashOut, ok]
    /// The circuit outputs: commitment (Poseidon(root, salt)), expectedHashOut (medication hash), and ok (1 if membership proven)
    function verify(
        bytes calldata proof,
        uint256[] calldata publicInputs,
        bytes calldata data
    ) external view returns (bool ok) {
        if (publicInputs.length != 3) revert InvalidArrayLength();

        // Decode Groth16 proof
        (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) = abi
            .decode(proof, (uint256[2], uint256[2][2], uint256[2]));

        uint256 inputCommitment = publicInputs[0]; // commitment = Poseidon(root, salt)
        uint256 inputExpectedHash = publicInputs[1]; // expectedHashOut = hash(medication)
        uint256 inputOk = publicInputs[2]; // ok = 1 if membership proven

        // Must match the expected medication hash
        if (inputExpectedHash != expectedMedicationHash) revert ValueMismatch();

        // Must claim successful proof
        if (inputOk != 1) revert ProofFailed();

        // Call verifier with 3 public signals
        uint256[3] memory input3 = [
            inputCommitment,
            inputExpectedHash,
            inputOk
        ];

        // Call the verifier directly (it expects uint[3] public signals)
        ok = verifier.verifyProof(a, b, c, input3);
    }
}
