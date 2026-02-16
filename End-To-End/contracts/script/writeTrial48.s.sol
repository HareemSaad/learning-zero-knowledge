// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {
    Groth16Verifier as SetContainsVerifier
} from "../src/verifiers/SetContains.sol";
import {SetContainsAdapter} from "../src/adapters/SetContainsAdapter.sol";

/// @title Complete System Deployment
/// @notice Deploys the entire verifiable policy system in correct order
contract DeployCompleteSystem is Script {
    string X_GREATER_THAN_Y_VERIFIER_ZKEY =
        vm.envString("X_GREATER_THAN_Y_VERIFIER_ZKEY");
    string IN_RANGE_VERIFIER_ZKEY = vm.envString("IN_RANGE_VERIFIER_ZKEY");
    string SET_CONTAINS_VERIFIER_ZKEY =
        vm.envString("SET_CONTAINS_VERIFIER_ZKEY");

    // Hash of "insulin" - keccak256 then modulo field prime
    uint256 constant INSULIN_HASH =
        uint256(keccak256("insulin"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Complete System Deployment ===");
        console.log("Deployer address:", deployer);
        console.log("Network:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Insulin Set Contains System
        SetContainsVerifier setContainsVerifier = new SetContainsVerifier();
        SetContainsAdapter setContainsAdapter = new SetContainsAdapter(
            address(setContainsVerifier),
            INSULIN_HASH,
            keccak256(abi.encodePacked(SET_CONTAINS_VERIFIER_ZKEY))
        );
        console.log("\n3. Insulin Set Contains System:");
        console.log("   SetContainsVerifier:", address(setContainsVerifier));
        console.log("   SetContainsAdapter:", address(setContainsAdapter));

        vm.stopBroadcast();

        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Insulin Contains Verifier:", address(setContainsVerifier));
        console.log("Insulin Contains Adapter:", address(setContainsAdapter));
    }
}
