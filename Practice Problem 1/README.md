## Problem 1

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

### Version 2: Removing the array
```circom
pragma circom 2.1.6;

// check if any one signal is zero
template Problem () {
    signal input a;
    signal input b;
    signal input c;

    signal output x;

    x <-- a * b * c;

    x === 0;
}

component main = Problem();
```

- Why is `x <-- a * b * c;`, a non-quadratic operation, allowed in Circom?
    - As circom breaks down the operations into a sequence of linear operations, it is able to handle non-quadratic operations.
    ```circom
    tmp <-- a * b;
    x <-- tmp * c;
    ```
    Note: X <== a * b * c; is not allowed as it is a non-quadratic operation.
    
- What is wrong with this approach? the signals do not occur in a constraint, so the circuit is not enforcing the correctness of x.


### Version 3: Dynamic number of input signals

```circom
pragma circom 2.1.6;

// check if any one signal is zero
template Problem (n) {
    // input array
    signal input a[n];

    // output signal
    signal output x;

    // temporary variable
    var tmp = a[0];

    // multiplication of all elements
    for (var i = 1; i < n; i++){
        tmp = tmp * a[i];
    }

    // write the result to the output signal
    x <-- tmp;

    // check if the result is zero
    x === 0;
}

component main = Problem(3);
```

- For input `"a": ["3", "0", "5"]` it generates the witness ["1", "0"]. 
    - `Index 0`: 1 means the circuit is satisfied and 0 means it is not.
    - `Index 1`: 0 means the output signal is 0.

- what is wrong with the following code?
    - `x<--tmp` renders the circuit useless, as
        - This circuit does not enforce the correctness of x because there are no constraints linking x to a[n].
        - A malicious prover could assign any value to x, and the verifier would not detect it.
        - This defeats the purpose of zero-knowledge proofs because the verifier is trusting the prover without actual verification.

- How can we fix it?
    - `x <== tmp` will not work as the loop is a non-quadratic operation hence it is going to be a non-quadratic constrain.
    - Use array for output signals and constrain each element. Here the ability to use `<==` means that the proof is verifiable.

```circom
pragma circom 2.1.6;

// check if any one signal is zero
template Problem (n) {
    // input array
    signal input a[n];

    // output signal
    signal output x[n];

    x[0] <== a[0];

    // multiplication of all elements
    for (var i = 1; i < n; i++){
        x[i] <== x[i-1] * a[i];
    }

    // check if the result is zero
    x[n-1] === 0;
}

component main = Problem(3);
```