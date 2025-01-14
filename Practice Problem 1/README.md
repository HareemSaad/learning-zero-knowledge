## Problem 1

### Commands
```bash
# To compile the circuit
circom problem.circom --r1cs --wasm --sym --c -o ./build

# To generate the witness
node build/problem_js/generate_witness.js build/problem_js/problem.wasm input.json build/witness.wtns

# To generate the proof
snarkjs wtns export json witness.wtns witness.json 
```

### Version 1: With only 3 input signals
```circom
pragma circom 2.1.6;

// check if any one signal is zero
template Problem () {
    signal input a;
    signal input b;
    signal input c;

    signal output x[2];

    x[0] <-- a * b;
    x[1] <-- x[0] * c;

    // if one of the signals is zero, output 1
    x[1] === 0;
}

component main = Problem();
```
 
- we use array for output signals as circom does not support quadratic operations so we could not have used one signal and iteratively multiplied it with each input signal.
