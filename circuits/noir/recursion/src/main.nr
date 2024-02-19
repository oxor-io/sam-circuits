use dep::std::verify_proof;

type Proof = [Field; 93];

global PROOF_LENGTH = 4;
global COMMON_PUB_INPUTS_LEN = 33;

/**
 * Searches for a pair of equal values within an array.
 *
 * This function scans through the provided array to find the first occurrence of two identical elements.
 * If such a pair is found, it returns the indexes of these elements as an array of two integers.
 * If the array does not contain any pair of equal values, the function returns [0,0] as a default case.
 */
fn are_only_uniq_values<N>(arr: [Field; N]) -> bool {
    // If delete (a == b) -> sort function will panic with reason: "array not sorted"
    let arr_sorted = arr.sort_via(|a: Field, b: Field| (a == b) | (a.lt(b)));

    let mut result = false;
    for i in 1..arr_sorted.len() {
        result |= (arr_sorted[i] == arr_sorted[i - 1]);
    }

    !result
}

/**
 * Verifies an array of proofs against a specified verification key and common public inputs.
 *
 * This function takes an array of proofs with `PROOF_LENGTH` length,
 * and verify each one of them using a verification key obtained from the `get_vk` function.
 *
 * Parameters:
 * - proofs: Array proofs to be verified.
 * - common_pub_inputs: An array representing the common public inputs for the verification
 *   process. This includes elements: the message hash (32) and the Merkle root(1).
 * - commitments: An array of commitments, where each commitment corresponds to a proof in the `proofs`
 *   array.
 * Note:
 * - Commitments must be uniq.
 * - `verify_proof` does not actually verify proof, but aggregates for future `final` verification.
 */
fn main(
    proofs: [Proof; PROOF_LENGTH],
    commitments: [Field; PROOF_LENGTH],
    common_pub_inputs: pub [Field; COMMON_PUB_INPUTS_LEN]
) -> pub Field {
    assert(are_only_uniq_values(commitments));

    let vk = get_vk();
    let vk_hash = get_vk_hash();

    let mut pub_inputs = common_pub_inputs.as_slice().push_back(0);
    for i in 0..PROOF_LENGTH {
        pub_inputs[pub_inputs.len() - 1] = commitments[i];
        verify_proof(vk, proofs[i].as_slice(), pub_inputs, vk_hash);
    }

    PROOF_LENGTH
}

// TODO replace with actual vk and vk_hash, when main circuit will be ready
fn get_vk() -> [Field] {
    [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
        12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
        24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
        48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
        60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
        72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83,
        84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
        96, 97, 98, 99, 100, 101, 102, 103,
        104, 105, 106, 107, 108,
        109, 110, 111, 112, 113
    ]
}

fn get_vk_hash() -> Field {
    1
}

mod tests {
    use crate::{are_only_uniq_values, main};

    #[test]
    fn test_uniq_values() {
        let arr = [1, 2, 3, 4, 5];
        let result = are_only_uniq_values(arr);
        assert(result);
    }

    #[test]
    fn test_not_uniq_values() {
        let arr = [1, 2, 1, 4, 5];
        let result = are_only_uniq_values(arr);
        assert(!result);
    }

    #[test]
    fn test_not_uniq_values_2() {
        let arr = [1, 2, 3, 4, 3];
        let result = are_only_uniq_values(arr);
        assert(!result);
    }

    #[test]
    fn test_not_uniq_values_3() {
        let arr = [1, 2, 3, 4, 4];
        let result = are_only_uniq_values(arr);
        assert(!result);
    }
}
