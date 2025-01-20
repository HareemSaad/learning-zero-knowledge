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