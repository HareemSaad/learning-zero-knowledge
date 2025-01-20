## Problem 2

### Commands
```bash
# To compile the circuit
circom problem.circom --r1cs --wasm --sym --c -o ./build

# To generate the witness
node build/problem_js/generate_witness.js build/problem_js/problem.wasm input.json build/witness.wtns

# To generate the proof
snarkjs wtns export json witness.wtns witness.json 

# To read witness.json
cat build/problem.sym
```

### Version 1: Looping to check if cumulative product is 1
```circom
pragma circom 2.1.6;

// check if all signals are 1
template Problem (n) {
    // input array
    signal input a[n];

    // output signal
    signal output out;

    // temporary signal
    signal temp[n];

    // assign the first element
    temp[0] <== a[0];

    // multiplication of all elements
    for (var i=1; i < n; i++) {
        temp[i] <== temp[i-1] * a[i];
    }

    // assign the output
    out <== temp[n-1];

    // check if the result is 1
    out === 1;
}

component main = Problem(3);
```