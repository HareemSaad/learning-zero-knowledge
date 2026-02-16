// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/adapters/SetContainsAdapter.sol";
import "../../src/IVerifierAdapter.sol";
import "../../src/IGroth16Verifier.sol";
import {Groth16Verifier} from "./../mocks/SetContains.sol";

contract SetContainsAdapterTest is Test {
    Groth16Verifier public verifier;
    SetContainsAdapter public adapter;
    bytes32 public zKeyHash = keccak256("set_contains_zkey_hash");
    uint256 public constant INSULIN_HASH =
        1918451500812936345219032480062932174755053122605062685245981358166483649839;

    // precomputed proof/public inputs from runs/insulin
    uint256[2] internal a;
    uint256[2][2] internal b;
    uint256[2] internal c;
    uint256[] internal publicInputs;

    function setUp() public {
        // 1️⃣ Deploy the verifier (from circom)
        verifier = new Groth16Verifier();

        // 2️⃣ Deploy the adapter with expected medication hash for insulin
        adapter = new SetContainsAdapter(
            address(verifier),
            INSULIN_HASH,
            zKeyHash
        );

        assertEq(adapter.zKeyHash(), zKeyHash);
        assertEq(adapter.expectedMedicationHash(), INSULIN_HASH);
        assertEq(address(adapter.verifier()), address(verifier));

        // 3️⃣ Load proof & inputs
        _loadProof();
    }

    function _loadProof() internal {
        // proof generated from insulin membership proof with updated circuit
        // using patient2.json with medications: ["insulin", "metoprolol", "warfarin"]
        a = [
            20853859342281962046576599891858676112808180317380942780336862137608909674166,
            18880121179567659819666551485506314271784143493862005349562188279519363823131
        ];
        b = [
            [
                11947983064450419120161577697271077525892730523241273991236513249742036541953,
                980905833503618623140781888953200166467310235607801421148818694193751702302
            ],
            [
                1939967933742618112736503094608400005959394372375239928750057633454716823450,
                11186506645879276793640913299087015764863278057566331544896595857757784292794
            ]
        ];
        c = [
            19294723616957795023193507431501497696713549320091433087567945957275141342585,
            17330740436882497925142939052776834584180257323467855693553910407333549047559
        ];

        // publicInputs = [commitment, expectedHashOut, ok]
        publicInputs = new uint256[](3);
        publicInputs[
            0
        ] = 62287452216058895539799727835192136848473127838405394434364715638161452925; // commitment = Poseidon(root, salt)
        publicInputs[1] = INSULIN_HASH; // expectedHashOut = hash("insulin")
        publicInputs[2] = 1; // ok = 1 (membership proven)
    }

    function test_VerifyProof_Succeeds() public view {
        bytes memory proof = abi.encode(a, b, c);
        bytes memory data = ""; // Empty data for standard SetContainsAdapter
        bool ok = adapter.verify(proof, publicInputs, data);
        assertTrue(ok, "Proof should verify successfully");
    }

    function test_RejectsWrongMedication() public {
        bytes memory proof = abi.encode(a, b, c);
        bytes memory data = ""; // Empty data for standard SetContainsAdapter

        uint256[] memory badInputs = new uint256[](3);
        badInputs[0] = publicInputs[0]; // correct commitment
        badInputs[1] = 999; // wrong medication hash
        badInputs[2] = 1;

        vm.expectRevert(SetContainsAdapter.ValueMismatch.selector);
        adapter.verify(proof, badInputs, data);
    }

    function test_RejectsInvalidOkFlag() public {
        bytes memory proof = abi.encode(a, b, c);

        uint256[] memory badInputs = new uint256[](3);
        badInputs[0] = publicInputs[0]; // correct commitment
        badInputs[1] = INSULIN_HASH; // correct medication
        badInputs[2] = 0; // wrong ok flag

        vm.expectRevert(SetContainsAdapter.ProofFailed.selector);
        adapter.verify(proof, badInputs, "");
    }

    function test_RejectsWrongInputLength() public {
        bytes memory proof = abi.encode(a, b, c);
        bytes memory data = ""; // Empty data for standard SetContainsAdapter

        uint256[] memory badInputs = new uint256[](2); // should be 3
        badInputs[0] = publicInputs[0];
        badInputs[1] = INSULIN_HASH;

        vm.expectRevert(SetContainsAdapter.InvalidArrayLength.selector);
        adapter.verify(proof, badInputs, data);
    }

    function test_RejectsWrongCommitment() public view {
        bytes memory proof = abi.encode(a, b, c);

        uint256[] memory badInputs = new uint256[](3);
        badInputs[0] = 999; // wrong commitment
        badInputs[1] = INSULIN_HASH;
        badInputs[2] = 1;

        // This will fail at the verifier level since commitment won't match
        bytes memory data = ""; // Empty data for standard SetContainsAdapter
        bool ok = adapter.verify(proof, badInputs, data);
        assertFalse(ok, "Should reject wrong commitment");
    }

    function test_RejectsZeroVerifierAddress() public {
        vm.expectRevert(SetContainsAdapter.ZeroAddress.selector);
        new SetContainsAdapter(address(0), INSULIN_HASH, zKeyHash);
    }

    function test_RejectsZeroMedicationHash() public {
        vm.expectRevert(SetContainsAdapter.InvalidConstrain.selector);
        new SetContainsAdapter(address(verifier), 0, zKeyHash);
    }

    function test_ZKeyHashIsSet() public view {
        assertEq(
            adapter.zKeyHash(),
            zKeyHash,
            "zKeyHash should match constructor input"
        );
    }

    function test_ExpectedMedicationHashIsSet() public view {
        assertEq(
            adapter.expectedMedicationHash(),
            INSULIN_HASH,
            "expectedMedicationHash should match constructor input"
        );
    }
}
