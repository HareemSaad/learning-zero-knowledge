## Circom 2
### Operators
| Operator | Description |
| --- | --- |
| `+` | Addition |
| `-` | Subtraction |
| `*` | Multiplication |
| `/` | Division |
| `===` | Equality/Constrain |
| `<--` | Assignment |
| `<==` | Equality/Constrain and Assignment |

### Keywords
| Keyword | Description |
| --- | --- |
| `signal` | Declares a signal (variables) |
| `template` | Declares a template (circuit layout) |
| `component` | Declares a component. A component is the initialization of a template. |

### Syntax Rules
Circom converts the arithmetic circuit into a Rank-1 Constraint System (R1CS) circuit. The R1CS circuit is a system of equations that can be represented as a matrix. The R1CS circuit is used to generate a proof that the circuit is satisfied.

It is in the pattern `A * B = C` where `A`, `B`, and `C` are vectors of signals. The R1CS circuit is represented as a matrix `M` where `M = [A, B, C]`.

#### Example 1: To create a circuit for $x^3$.
We can represent it as:

```circom
pragma circom 2.1.6;

template Example () {
   // Declaration of signals.  
   signal input a;  
   signal a1;
   signal output a2;  

   a1 <== a * a;
   a2 <== a1 * a1;

}

component main {public [a]} = Example();
```

we do not do `a2 <== a * a * a` the R1CS pattern is `A * B = C` so we need to break it down into two steps.

#### Example 2: To create a circuit for x/x (modular division).

```circom
pragma circom 2.1.6;

template Example () {
   // Declaration of signals.  
   signal input a;  

   signal output a2;  

   a2 <== a/a;
}

component main {public [a]} = Example();
```

This will fail citing error `Non quadratic constraints are not allowed!`

R1CS is a constraint system and its rules only apply to the constraints thus we can separate the assignment or in other words, the witness/proof generation from the constraint. So we can break up the assignment and constrain into 2 separate steps.

```circom
// assign
a2 <-- a/a;

// constrain
a2 === 1;

// or constrain could be 
a2 * a === a;
```     

#### Example 3: Importing Templates

```circom
pragma circom 2.1.6;

// import lib
include "circomlib/poseidon.circom";

template Example () {
    signal input a;
    signal input b;

    // create instance of hash function with 2 inputs
    component hash = Poseidon(2);

    // initialize inputs
    hash.inputs[0] <== a;
    hash.inputs[1] <== b;

    log("hash", hash.out);
}

// a is public input, b is not
component main { public [ a ] } = Example();

/* INPUT = {
    "a": "5",
    "b": "77"
} */
```

### Libraries
- [Poseidon](https://github.com/iden3/circomlib/blob/master/circuits/poseidon.circom) -- Poseidon is a hash function designed to minimize prover and verifier complexities when Zero-Knowledge Proofs are generated and validated as a reason it's very commonly used, we will utilize Poseidon more in the next lesson. 

### References and Resources
- [Playground](https://zkrepl.dev/)
