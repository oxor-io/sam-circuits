pragma circom 2.0.2;

include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/multiplexer.circom";

include "bigint.circom";
include "bigint_4x64_mult.circom";
include "bigint_func.circom";
include "secp256k1_func.circom";
include "secp256k1_utils.circom";

// Implements:
// x_1 + x_2 + x_3 - lambda^2 = 0 mod p
// where p is the secp256k1 field size
// and lambda is the slope of the line between (x_1, y_1) and (x_2, y_2)
// this equation is equivalent to:
// x1^3 + x2^3 - x1^2x2 - x1x2^2 + x2^2x3 + x1^2x3 - 2x1x2x3 - y2^2 - 2y1y2 - y1^2 = 0 mod p
template AddUnequalCubicConstraint() {
    signal input x1[4];
    signal input y1[4];
    signal input x2[4];
    signal input y2[4];
    signal input x3[4];
    signal input y3[4];

    signal x13[10]; // 197 bits
    component x13Comp = A3NoCarry();
    for (var i = 0; i < 4; i++) x13Comp.a[i] <== x1[i];
    for (var i = 0; i < 10; i++) x13[i] <== x13Comp.a3[i];

    signal x23[10]; // 197 bits
    component x23Comp = A3NoCarry();
    for (var i = 0; i < 4; i++) x23Comp.a[i] <== x2[i];
    for (var i = 0; i < 10; i++) x23[i] <== x23Comp.a3[i];

    signal x12x2[10]; // 197 bits
    component x12x2Comp = A2B1NoCarry();
    for (var i = 0; i < 4; i++) x12x2Comp.a[i] <== x1[i];
    for (var i = 0; i < 4; i++) x12x2Comp.b[i] <== x2[i];
    for (var i = 0; i < 10; i++) x12x2[i] <== x12x2Comp.a2b1[i];

    signal x1x22[10]; // 197 bits
    component x1x22Comp = A2B1NoCarry();
    for (var i = 0; i < 4; i++) x1x22Comp.a[i] <== x2[i];
    for (var i = 0; i < 4; i++) x1x22Comp.b[i] <== x1[i];
    for (var i = 0; i < 10; i++) x1x22[i] <== x1x22Comp.a2b1[i];

    signal x22x3[10]; // 197 bits
    component x22x3Comp = A2B1NoCarry();
    for (var i = 0; i < 4; i++) x22x3Comp.a[i] <== x2[i];
    for (var i = 0; i < 4; i++) x22x3Comp.b[i] <== x3[i];
    for (var i = 0; i < 10; i++) x22x3[i] <== x22x3Comp.a2b1[i];

    signal x12x3[10]; // 197 bits
    component x12x3Comp = A2B1NoCarry();
    for (var i = 0; i < 4; i++) x12x3Comp.a[i] <== x1[i];
    for (var i = 0; i < 4; i++) x12x3Comp.b[i] <== x3[i];
    for (var i = 0; i < 10; i++) x12x3[i] <== x12x3Comp.a2b1[i];

    signal x1x2x3[10]; // 197 bits
    component x1x2x3Comp = A1B1C1NoCarry();
    for (var i = 0; i < 4; i++) x1x2x3Comp.a[i] <== x1[i];
    for (var i = 0; i < 4; i++) x1x2x3Comp.b[i] <== x2[i];
    for (var i = 0; i < 4; i++) x1x2x3Comp.c[i] <== x3[i];
    for (var i = 0; i < 10; i++) x1x2x3[i] <== x1x2x3Comp.a1b1c1[i];

    signal y12[7]; // 130 bits
    component y12Comp = A2NoCarry();
    for (var i = 0; i < 4; i++) y12Comp.a[i] <== y1[i];
    for (var i = 0; i < 7; i++) y12[i] <== y12Comp.a2[i];

    signal y22[7]; // 130 bits
    component y22Comp = A2NoCarry();
    for (var i = 0; i < 4; i++) y22Comp.a[i] <== y2[i];
    for (var i = 0; i < 7; i++) y22[i] <== y22Comp.a2[i];

    signal y1y2[7]; // 130 bits
    component y1y2Comp = BigMultNoCarry(64, 64, 64, 4, 4);
    for (var i = 0; i < 4; i++) y1y2Comp.a[i] <== y1[i];
    for (var i = 0; i < 4; i++) y1y2Comp.b[i] <== y2[i];
    for (var i = 0; i < 7; i++) y1y2[i] <== y1y2Comp.out[i];

    component zeroCheck = CheckCubicModPIsZero(200); // 200 bits per register
    for (var i = 0; i < 10; i++) {
        if (i < 7) {
            zeroCheck.in[i] <== x13[i] + x23[i] - x12x2[i] - x1x22[i] + x22x3[i] + x12x3[i] - 2 * x1x2x3[i] - y12[i] + 2 * y1y2[i] - y22[i];
        } else {
            zeroCheck.in[i] <== x13[i] + x23[i] - x12x2[i] - x1x22[i] + x22x3[i] + x12x3[i] - 2 * x1x2x3[i];
        }
    }
}

// Implements:
// x3y2 + x2y3 + x2y1 - x3y1 - x1y2 - x1y3 == 0 mod p
// for secp prime p
// used to show (x1, y1), (x2, y2), (x3, -y3) are co-linear
template Secp256k1PointOnLine() {
    signal input x1[4];
    signal input y1[4];

    signal input x2[4];
    signal input y2[4];

    signal input x3[4];
    signal input y3[4];

    // first, we compute representations of x3y2, x2y3, x2y1, x3y1, x1y2, x1y3.
    // these representations have overflowed, nonnegative registers
    signal x3y2[7];
    component x3y2Comp = BigMultNoCarry(64, 64, 64, 4, 4);
    for (var i = 0; i < 4; i++) x3y2Comp.a[i] <== x3[i];
    for (var i = 0; i < 4; i++) x3y2Comp.b[i] <== y2[i];
    for (var i = 0; i < 7; i++) x3y2[i] <== x3y2Comp.out[i]; // 130 bits

    signal x3y1[7];
    component x3y1Comp = BigMultNoCarry(64, 64, 64, 4, 4);
    for (var i = 0; i < 4; i++) x3y1Comp.a[i] <== x3[i];
    for (var i = 0; i < 4; i++) x3y1Comp.b[i] <== y1[i];
    for (var i = 0; i < 7; i++) x3y1[i] <== x3y1Comp.out[i]; // 130 bits

    signal x2y3[7];
    component x2y3Comp = BigMultNoCarry(64, 64, 64, 4, 4);
    for (var i = 0; i < 4; i++) x2y3Comp.a[i] <== x2[i];
    for (var i = 0; i < 4; i++) x2y3Comp.b[i] <== y3[i];
    for (var i = 0; i < 7; i++) x2y3[i] <== x2y3Comp.out[i]; // 130 bits

    signal x2y1[7];
    component x2y1Comp = BigMultNoCarry(64, 64, 64, 4, 4);
    for (var i = 0; i < 4; i++) x2y1Comp.a[i] <== x2[i];
    for (var i = 0; i < 4; i++) x2y1Comp.b[i] <== y1[i];
    for (var i = 0; i < 7; i++) x2y1[i] <== x2y1Comp.out[i]; // 130 bits

    signal x1y3[7];
    component x1y3Comp = BigMultNoCarry(64, 64, 64, 4, 4);
    for (var i = 0; i < 4; i++) x1y3Comp.a[i] <== x1[i];
    for (var i = 0; i < 4; i++) x1y3Comp.b[i] <== y3[i];
    for (var i = 0; i < 7; i++) x1y3[i] <== x1y3Comp.out[i]; // 130 bits

    signal x1y2[7];
    component x1y2Comp = BigMultNoCarry(64, 64, 64, 4, 4);
    for (var i = 0; i < 4; i++) x1y2Comp.a[i] <== x1[i];
    for (var i = 0; i < 4; i++) x1y2Comp.b[i] <== y2[i];
    for (var i = 0; i < 7; i++) x1y2[i] <== x1y2Comp.out[i]; // 130 bits

    component zeroCheck = CheckQuadraticModPIsZero(132);
    for (var i = 0; i < 7; i++) {
        zeroCheck.in[i] <== x3y2[i] + x2y3[i] + x2y1[i] - x3y1[i] - x1y2[i] - x1y3[i];
    }
}

template Secp256k1PointOnTangent() {
    signal input x1[4];
    signal input y1[4];
    signal input x3[4];
    signal input y3[4];

    // first, we compute representations of y1^2, y1y3, x1^3, x1^2x3
    signal y12[7]; // 130 bits
    component y12Comp = A2NoCarry();
    for (var i = 0; i < 4; i++) y12Comp.a[i] <== y1[i];
    for (var i = 0; i < 7; i++) y12[i] <== y12Comp.a2[i];

    signal y1y3[7]; // 130 bits
    component y1y3Comp = BigMultNoCarry(64, 64, 64, 4, 4);
    for (var i = 0; i < 4; i++) y1y3Comp.a[i] <== y1[i];
    for (var i = 0; i < 4; i++) y1y3Comp.b[i] <== y3[i];
    for (var i = 0; i < 7; i++) y1y3[i] <== y1y3Comp.out[i];

    signal x13[10]; // 197 bits
    component x13Comp = A3NoCarry();
    for (var i = 0; i < 4; i++) x13Comp.a[i] <== x1[i];
    for (var i = 0; i < 10; i++) x13[i] <== x13Comp.a3[i];

    signal x12x3[10]; // 197 bits
    component x12x3Comp = A2B1NoCarry();
    for (var i = 0; i < 4; i++) x12x3Comp.a[i] <== x1[i];
    for (var i = 0; i < 4; i++) x12x3Comp.b[i] <== x3[i];
    for (var i = 0; i < 10; i++) x12x3[i] <== x12x3Comp.a2b1[i];

    component zeroCheck = CheckCubicModPIsZero(199);
    for (var i = 0; i < 10; i++) {
        if (i < 7) zeroCheck.in[i] <== 2 * y12[i] + 2 * y1y3[i] - 3 * x13[i] + 3 * x12x3[i];
        else zeroCheck.in[i] <== -3 * x13[i] + 3 * x12x3[i];
    }
}

// Implements:
// x^3 + 7 - y^2 == 0 mod p
// where p is the secp256k1 field size
template Secp256k1PointOnCurve() {
    signal input x[4];
    signal input y[4];

    // first, we compute representations of x^3 and y^2.
    // these representations have overflowed, nonnegative registers
    signal x3[10]; // 197 bits
    component x3Comp = A3NoCarry();
    for (var i = 0; i < 4; i++) x3Comp.a[i] <== x[i];
    for (var i = 0; i < 10; i++) x3[i] <== x3Comp.a3[i];

    signal y2[7]; // 130 bits
    component y2Comp = A2NoCarry();
    for (var i = 0; i < 4; i++) y2Comp.a[i] <== y[i];
    for (var i = 0; i < 7; i++) y2[i] <== y2Comp.a2[i];

    component zeroCheck = CheckCubicModPIsZero(197); // 197 bits per register
    for (var i = 0; i < 10; i++) {
        if (i == 0) zeroCheck.in[i] <== x3[i] - y2[i] + 7;
        else if (i < 7) zeroCheck.in[i] <== x3[i] - y2[i];
        else zeroCheck.in[i] <== x3[i];
    }
}

template Secp256k1AddUnequal(n, k) {
    assert(n == 64 && k == 4);

    signal input a[2][k];
    signal input b[2][k];

    signal output out[2][k];
    var x1[4];
    var y1[4];
    var x2[4];
    var y2[4];
    for(var i=0;i<4;i++){
        x1[i] = a[0][i];
        y1[i] = a[1][i];
        x2[i] = b[0][i];
        y2[i] = b[1][i];
    }

    var tmp[2][100] = secp256k1_addunequal_func(n, k, x1, y1, x2, y2);
    for(var i = 0; i < k;i++){
        out[0][i] <-- tmp[0][i];
        out[1][i] <-- tmp[1][i];
    }

    component cubic_constraint = AddUnequalCubicConstraint();
    for(var i = 0; i < k; i++){
        cubic_constraint.x1[i] <== x1[i];
        cubic_constraint.y1[i] <== y1[i];
        cubic_constraint.x2[i] <== x2[i];
        cubic_constraint.y2[i] <== y2[i];
        cubic_constraint.x3[i] <== out[0][i];
        cubic_constraint.y3[i] <== out[1][i];
    }

    component point_on_line = Secp256k1PointOnLine();
    for(var i = 0; i < k; i++){
        point_on_line.x1[i] <== a[0][i];
        point_on_line.y1[i] <== a[1][i];
        point_on_line.x2[i] <== b[0][i];
        point_on_line.y2[i] <== b[1][i];
        point_on_line.x3[i] <== out[0][i];
        point_on_line.y3[i] <== out[1][i];
    }

    component x_check_in_range = CheckInRangeSecp256k1();
    component y_check_in_range = CheckInRangeSecp256k1();
    for(var i = 0; i < k; i++){
        x_check_in_range.in[i] <== out[0][i];
        y_check_in_range.in[i] <== out[1][i];
    }
}

template Secp256k1Double(n, k) {
    assert(n == 64 && k == 4);

    signal input in[2][k];

    signal output out[2][k];
    var x1[4];
    var y1[4];
    for(var i=0;i<4;i++){
        x1[i] = in[0][i];
        y1[i] = in[1][i];
    }

    var tmp[2][100] = secp256k1_double_func(n, k, x1, y1);
    for(var i = 0; i < k;i++){
        out[0][i] <-- tmp[0][i];
        out[1][i] <-- tmp[1][i];
    }

    component point_on_tangent = Secp256k1PointOnTangent();
    for(var i = 0; i < k; i++){
        point_on_tangent.x1[i] <== x1[i];
        point_on_tangent.y1[i] <== y1[i];
        point_on_tangent.x3[i] <== out[0][i];
        point_on_tangent.y3[i] <== out[1][i];
    }

    component point_on_curve = Secp256k1PointOnCurve();
    for(var i = 0; i < k; i++){
        point_on_curve.x[i] <== out[0][i];
        point_on_curve.y[i] <== out[1][i];
    }

    component x_check_in_range = CheckInRangeSecp256k1();
    component y_check_in_range = CheckInRangeSecp256k1();
    for(var i = 0; i < k; i++){
        x_check_in_range.in[i] <== out[0][i];
        y_check_in_range.in[i] <== out[1][i];
    }

    component x3_eq_x1 = BigIsEqual(4);
    for(var i = 0; i < k; i++){
        x3_eq_x1.in[0][i] <== out[0][i];
        x3_eq_x1.in[1][i] <== x1[i];
    }
    x3_eq_x1.out === 0;
}

template Secp256k1ScalarMult(n, k) {
    signal input scalar[k];
    signal input point[2][k];

    signal output out[2][k];

    component n2b[k];
    for (var i = 0; i < k; i++) {
        n2b[i] = Num2Bits(n);
        n2b[i].in <== scalar[i];
    }

    // has_prev_non_zero[n * i + j] == 1 if there is a nonzero bit in location [i][j] or higher order bit
    component has_prev_non_zero[k * n];
    for (var i = k - 1; i >= 0; i--) {
        for (var j = n - 1; j >= 0; j--) {
            has_prev_non_zero[n * i + j] = OR();
            if (i == k - 1 && j == n - 1) {
                has_prev_non_zero[n * i + j].a <== 0;
                has_prev_non_zero[n * i + j].b <== n2b[i].out[j];
            } else {
                has_prev_non_zero[n * i + j].a <== has_prev_non_zero[n * i + j + 1].out;
                has_prev_non_zero[n * i + j].b <== n2b[i].out[j];
            }
        }
    }

    signal partial[n * k][2][k];
    signal intermed[n * k - 1][2][k];
    component adders[n * k - 1];
    component doublers[n * k - 1];
    for (var i = k - 1; i >= 0; i--) {
        for (var j = n - 1; j >= 0; j--) {
            if (i == k - 1 && j == n - 1) {
                for (var idx = 0; idx < k; idx++) {
                    partial[n * i + j][0][idx] <== point[0][idx];
                    partial[n * i + j][1][idx] <== point[1][idx];
                }
            }
            if (i < k - 1 || j < n - 1) {
                adders[n * i + j] = Secp256k1AddUnequal(n, k);
                doublers[n * i + j] = Secp256k1Double(n, k);
                for (var idx = 0; idx < k; idx++) {
                    doublers[n * i + j].in[0][idx] <== partial[n * i + j + 1][0][idx];
                    doublers[n * i + j].in[1][idx] <== partial[n * i + j + 1][1][idx];
                }
                for (var idx = 0; idx < k; idx++) {
                    adders[n * i + j].a[0][idx] <== doublers[n * i + j].out[0][idx];
                    adders[n * i + j].a[1][idx] <== doublers[n * i + j].out[1][idx];
                    adders[n * i + j].b[0][idx] <== point[0][idx];
                    adders[n * i + j].b[1][idx] <== point[1][idx];
                }
                // partial[n * i + j]
                // = has_prev_non_zero[n * i + j + 1] * ((1 - n2b[i].out[j]) * doublers[n * i + j] + n2b[i].out[j] * adders[n * i + j])
                //   + (1 - has_prev_non_zero[n * i + j + 1]) * point
                for (var idx = 0; idx < k; idx++) {
                    intermed[n * i + j][0][idx] <== n2b[i].out[j] * (adders[n * i + j].out[0][idx] - doublers[n * i + j].out[0][idx]) + doublers[n * i + j].out[0][idx];
                    intermed[n * i + j][1][idx] <== n2b[i].out[j] * (adders[n * i + j].out[1][idx] - doublers[n * i + j].out[1][idx]) + doublers[n * i + j].out[1][idx];
                    partial[n * i + j][0][idx] <== has_prev_non_zero[n * i + j + 1].out * (intermed[n * i + j][0][idx] - point[0][idx]) + point[0][idx];
                    partial[n * i + j][1][idx] <== has_prev_non_zero[n * i + j + 1].out * (intermed[n * i + j][1][idx] - point[1][idx]) + point[1][idx];
                }
            }
        }
    }

    for (var idx = 0; idx < k; idx++) {
        out[0][idx] <== partial[0][0][idx];
        out[1][idx] <== partial[0][1][idx];
    }
}

template Secp256k1ScalarMultWindow(n, k, stride) {
    signal input scalar[k];
    signal input point[2][k];

    signal output out[2][k];

    var BITS = n * k;
    var num_strides = BITS \ stride;
    if (BITS % stride > 0) {
	    num_strides = num_strides + 1;
    }

    // compute dynamic window of: 2 * point, 3 * point, .. (2 ** stride - 1) * point
    signal cache[(1 << stride) - 2][2][k];
    component cache_doublers[(1 << (stride - 1)) - 1];
    component cache_adders[(1 << (stride - 1)) - 1];
    var cd_cnt = 0;
    var ca_cnt = 0;
    for (var i = 1; i < stride; i++) {
	for (var j = (1 << i) \ 2; j < (1 << i); j++) {
	    cache_doublers[cd_cnt] = Secp256k1Double(n, k);
	    cache_adders[ca_cnt] = Secp256k1AddUnequal(n, k);

	    for (var idx = 0; idx < k; idx++) {
		if (j > 1) {
		    cache_doublers[cd_cnt].in[0][idx] <== cache[j - 2][0][idx];
		    cache_doublers[cd_cnt].in[1][idx] <== cache[j - 2][1][idx];
		} else {
		    cache_doublers[cd_cnt].in[0][idx] <== point[0][idx];
		    cache_doublers[cd_cnt].in[1][idx] <== point[1][idx];
		}
	    }
	    for (var idx = 0; idx < k; idx++) {
		cache[2 * j - 2][0][idx] <== cache_doublers[cd_cnt].out[0][idx];
		cache[2 * j - 2][1][idx] <== cache_doublers[cd_cnt].out[1][idx];
	    }

	    for (var idx = 0; idx < k; idx++) {
		cache_adders[ca_cnt].a[0][idx] <== cache[2 * j - 2][0][idx];
		cache_adders[ca_cnt].a[1][idx] <== cache[2 * j - 2][1][idx];
		cache_adders[ca_cnt].b[0][idx] <== point[0][idx];
		cache_adders[ca_cnt].b[1][idx] <== point[1][idx];
	    }
	    for (var idx = 0; idx < k; idx++) {
		cache[2 * j + 1 - 2][0][idx] <== cache_adders[ca_cnt].out[0][idx];
		cache[2 * j + 1 - 2][1][idx] <== cache_adders[ca_cnt].out[1][idx];
	    }

	    cd_cnt = cd_cnt + 1;
	    ca_cnt = ca_cnt + 1;
	}
    }

    component n2b[k];
    for (var i = 0; i < k; i++) {
        n2b[i] = Num2Bits(n);
        n2b[i].in <== scalar[i];
    }

    // selector[i] contains a value in [0, ..., 2**stride - 1]
    component selectors[num_strides];
    for (var i = 0; i < num_strides; i++) {
        selectors[i] = Bits2Num(stride);
        for (var j = 0; j < stride; j++) {
            var bit_idx1 = (i * stride + j) \ n;
            var bit_idx2 = (i * stride + j) % n;
            if (bit_idx1 < k) {
                selectors[i].in[j] <== n2b[bit_idx1].out[bit_idx2];
            } else {
                selectors[i].in[j] <== 0;
            }
        }
    }

    // select from 2 concatenated k-register outputs using a 2 ** stride bit selector
    component multiplexers[num_strides];
    for (var i = 0; i < num_strides; i++) {
	multiplexers[i] = Multiplexer(2 * k, (1 << stride));
        multiplexers[i].sel <== selectors[i].out;
        for (var l = 0; l < 2; l++) {
            for (var idx = 0; idx < k; idx++) {
                multiplexers[i].inp[0][l * k + idx] <== point[l][idx];
		multiplexers[i].inp[1][l * k + idx] <== point[l][idx];
                for (var j = 2; j < (1 << stride); j++) {
                    multiplexers[i].inp[j][l * k + idx] <== cache[j - 2][l][idx];
                }
            }
        }
    }

    component is_zero[num_strides];
    for (var i = 0; i < num_strides; i++) {
        is_zero[i] = IsZero();
        is_zero[i].in <== selectors[i].out;
    }

    // has_prev_nonzero[i] = 1 if at least one of the selections in privkey in strides i+1, i+2, .. is non-zero
    component has_prev_nonzero[num_strides - 1];
    for (var i = num_strides - 2; i >= 0; i--) {
        has_prev_nonzero[i] = OR();
	if (i == num_strides - 2) {
            has_prev_nonzero[i].a <== 0;
	} else {
	    has_prev_nonzero[i].a <== has_prev_nonzero[i + 1].out;
	}
        has_prev_nonzero[i].b <== 1 - is_zero[i + 1].out;
    }

    signal partial[num_strides][2][k];
    signal intermed[num_strides - 1][2][k];
    component adders[num_strides - 1];
    component doublers[(num_strides - 1) * stride];
    for (var i = num_strides - 1; i >= 0; i--) {
	if (i == num_strides - 1) {
	    for (var idx = 0; idx < k; idx++) {
		partial[i][0][idx] <== multiplexers[i].out[idx];
		partial[i][1][idx] <== multiplexers[i].out[k + idx];
	    }
	} else {
	    for (var j = 0; j < stride; j++) {
		doublers[i * stride + j] = Secp256k1Double(n, k);
		if (j == 0) {
		    for (var idx = 0; idx < k; idx++) {
			doublers[i * stride].in[0][idx] <== partial[i + 1][0][idx];
			doublers[i * stride].in[1][idx] <== partial[i + 1][1][idx];
		    }
		} else {
		    for (var idx = 0; idx < k; idx++) {
			doublers[i * stride + j].in[0][idx] <== doublers[i * stride + j - 1].out[0][idx];
			doublers[i * stride + j].in[1][idx] <== doublers[i * stride + j - 1].out[1][idx];
		    }
		}
	    }

	    adders[i] = Secp256k1AddUnequal(n, k);
	    for (var idx = 0; idx < k; idx++) {
		adders[i].a[0][idx] <== doublers[i * stride + stride - 1].out[0][idx];
		adders[i].a[1][idx] <== doublers[i * stride + stride - 1].out[1][idx];
		adders[i].b[0][idx] <== multiplexers[i].out[idx];
		adders[i].b[1][idx] <== multiplexers[i].out[k + idx];
	    }

	    // partial[i] = has_prev_nonzero[i] * (is_zero[i] * doublers[i * stride + stride - 1] + (1 - is_zero[i]) * adders[i])
            //              + (1 - has_prev_nonzero[i]) * multiplexers[i]
	    for (var idx = 0; idx < k; idx++) {
		intermed[i][0][idx] <== is_zero[i].out * (doublers[i * stride + stride - 1].out[0][idx] - adders[i].out[0][idx]) + adders[i].out[0][idx];
		intermed[i][1][idx] <== is_zero[i].out * (doublers[i * stride + stride - 1].out[1][idx] - adders[i].out[1][idx]) + adders[i].out[1][idx];
		partial[i][0][idx] <== has_prev_nonzero[i].out * (intermed[i][0][idx] - multiplexers[i].out[idx]) + multiplexers[i].out[idx];
		partial[i][1][idx] <== has_prev_nonzero[i].out * (intermed[i][1][idx] - multiplexers[i].out[k + idx]) + multiplexers[i].out[k + idx];
	    }
	}
    }

    for (var idx = 0; idx < k; idx++) {
        out[0][idx] <== partial[0][0][idx];
        out[1][idx] <== partial[0][1][idx];
    }
}