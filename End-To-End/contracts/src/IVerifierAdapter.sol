// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVerifierAdapter {
    function zKeyHash() external view returns (bytes32);

    /// proof: ABI-encoded (a,b,c) for Groth16:
    ///   a: uint256[2], b: uint256[2][2], c: uint256[2]
    /// publicInputs: flattened Groth16 inputs as field elements
    function verify(bytes calldata proof, uint256[] calldata publicInputs, bytes calldata data)
        external
        view
        returns (bool ok);
}
