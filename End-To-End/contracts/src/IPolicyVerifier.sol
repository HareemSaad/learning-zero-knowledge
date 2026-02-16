// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPolicyVerifier {
    function checkTrialEligibility(
        address[] calldata adapters,
        bytes[] calldata proofs,
        uint256[][] calldata publicInputs
    ) external view returns (bool eligible);
}
