pragma circom 2.1.6;

// check if any one signal is zero
template Problem () {
    signal input a;
    signal input b;
    signal input c;

    signal output x[2];

    x[0] <-- a * b;
    x[1] <-- x[0] * c;

    x[1] === 0;
}

component main = Problem();