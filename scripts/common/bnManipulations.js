function bigintToArray(n, k, x) {
    let mod = 1n;
    for (let idx = 0; idx < n; idx++) {
        mod = mod * 2n;
    }

    const ret = [];
    let xTemp = x;
    for (let idx = 0; idx < k; idx++) {
        ret.push(xTemp % mod);
        xTemp = xTemp / mod;
    }
    return ret;
}

function bigintToUint8Array(x) {
    const ret = new Uint8Array(32);
    for (let idx = 31; idx >= 0; idx--) {
        ret[idx] = Number(x % 256n);
        x = x / 256n;
    }
    return ret;
}

function Uint8ArrayToBigint(x) {
    let ret = 0n;
    for (let idx = 0; idx < x.length; idx++) {
        ret = ret * 256n;
        ret = ret + BigInt(x[idx]);
    }
    return ret;
}

module.exports = {
    bigintToArray,
    bigintToUint8Array,
    Uint8ArrayToBigint,
};
