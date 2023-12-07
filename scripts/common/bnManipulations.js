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

function bigintToArrayBitwise(n, k, x) {
    if (!n || !k) throw new Error("bigintToArrayBitwise: n == 0 || k == 0");
    if (x < 0n) throw new Error("bigintToArrayBitwise: x < 0");
    if (n * k < BigInt(x.toString(2).length)) throw new Error("X too large, Information can be lost. n * k < x.length");

    const mask = (1n << n) - 1n;

    const res = [];
    for (let i = 0; i < k; i++) {
        res.push(x & mask);
        x >>= n;
    }
    return res;
}

function bigintToUint8Array(x) {
    const ret = new Uint8Array(32);
    for (let idx = 31; idx >= 0; idx--) {
        ret[idx] = Number(x % 256n);
        x = x / 256n;
    }
    return ret;
}

function bigintToUint8ArrayBitwise(x) {
    if (typeof x !== "bigint") throw new Error("bigintToUint8ArrayBitwise: x is not a bigint");
    const uint8Size = 8n;
    const mask = 255n;
    const ret = new Uint8Array(32);

    for (let idx = 31; idx >= 0; idx--) {
        ret[idx] = Number(x & mask);
        x >>= uint8Size;

        if (!x) break;
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

function Uint8ArrayToBigintBitwise(x) {
    let ret = 0n;
    for (let i = 0; i < x.length; i++) {
        ret <<= 8n;
        ret |= BigInt(x[i]);
    }
    return ret;
}

module.exports = {
    bigintToArray,
    bigintToUint8Array,
    Uint8ArrayToBigint,
    bigintToArrayBitwise,
    bigintToUint8ArrayBitwise,
    Uint8ArrayToBigintBitwise,
};
