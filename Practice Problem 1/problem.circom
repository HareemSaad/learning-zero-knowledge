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