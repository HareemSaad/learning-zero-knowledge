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