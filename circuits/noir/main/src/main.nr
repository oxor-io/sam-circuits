mod pub_key;
mod u8_array;
mod merkle_tree;

use dep::std::hash::keccak256;
use pub_key::{PubKey, RawSignature};
use u8_array::{U8Array, WORD_LEN};
use merkle_tree::{compute_merkle_root, mimc_sponge, MIMC_SPONGE_KEY};

global LEVELS: Field = 5; // Depth of the tree
type TREE_HASH_PATH = [Field; LEVELS];

fn main(
    pub_key: PubKey,
    sig: RawSignature,
    msg_hash: pub U8Array<WORD_LEN>,
    root: pub Field,
    path_indexes: Field,
    hash_path: TREE_HASH_PATH
) -> pub Field {
    let is_sig_valid = pub_key.is_sig_valid_for_msg(sig, msg_hash.as_array());
    assert(is_sig_valid, "Invalid sig");

    // Convert pk to address
    let addr = pub_key.get_address().as_field();

    // Get user leaf (hash of address)
    let user_leaf: [Field; 1] = mimc_sponge([addr], MIMC_SPONGE_KEY);
    let user_leaf = user_leaf[0];

    // Verify that address in Merkle Trie
    let result_root = compute_merkle_root(user_leaf, path_indexes, hash_path);
    assert_eq(result_root, root, "The roots don't match");

    // Return commitment
    compute_commitment(addr, msg_hash.as_field_array())
}

fn compute_commitment(addr: Field, msg_hash: [Field; WORD_LEN]) -> Field {
    let commitment_slice = msg_hash.as_slice().push_front(addr);

    let mut commitment_array = [0; WORD_LEN + 1];
    for i in 0..commitment_array.len() {
        commitment_array[i] = commitment_slice[i];
    }

    let commitment: [Field; 1] = mimc_sponge(commitment_array, MIMC_SPONGE_KEY);
    commitment[0]
}

mod tests {
    use crate::pub_key::{U8Array, PubKey};
    use crate::{main, compute_commitment};

    global default_msg_hash = [
            2, 207, 71, 217, 145, 255, 62, 188,
            249, 9, 45, 82, 88, 164, 226, 63,
            176, 171, 77, 186, 72, 238, 53, 94,
            195, 131, 67, 182, 187, 42, 212, 140
        ];

    global default_msg_hash_u8_array = U8Array {
        arr: default_msg_hash
    };

    global default_pub_key = PubKey {
            x: [
                131, 24, 83, 91, 84, 16, 93, 74,
                122, 174, 96, 192, 143, 196, 95, 150,
                135, 24, 27, 79, 223, 198, 37, 189,
                26, 117, 63, 167, 57, 127, 237, 117
            ],
            y: [
                53, 71, 241, 28, 168, 105, 102, 70,
                242, 243, 172, 176, 142, 49, 1, 106,
                250, 194, 62, 99, 12, 93, 17, 245,
                159, 97, 254, 245, 123, 13, 42, 165
            ]
        };

    global default_sig = [
            202, 253, 131, 117, 218, 12, 92, 139, 45, 202, 191,
            23, 123, 110, 15, 26, 199, 178, 234, 37, 148, 148,
            94, 189, 132, 104, 159, 85, 202, 82, 6, 91, 120,
            69, 87, 70, 11, 174, 63, 133, 162, 246, 222, 140,
            123, 158, 141, 3, 254, 120, 46, 196, 212, 229, 75,
            14, 101, 115, 209, 33, 115, 10, 145, 53
        ];

    global default_path_indecies = 0;
    global default_root = 7378323513472991738372527896654445137493089583233093119951646841738120031371;
    global  default_path_elements = [
            9479145765164306604898661246306912585240247746526471519759854195178979516700,
            10821577188404079746999828440545293402557390793255312676266883079953085672921,
            10266675050323606453909836805900148358798034671050728166354968531595868722006,
            8575350884931261137867066738147375482425232494266355398216179294178508866708,
            18097266179879782427361438755277450939722755112152115227098348943187633376449
        ];

    #[test]
    fn test_main_successfull_scenario() {
        let _ = main(
            default_pub_key,
            default_sig,
            default_msg_hash_u8_array,
            default_root,
            default_path_indecies,
            default_path_elements
        );
    }

    #[test(should_fail)]
    fn test_main_fail_scenario_root() {
        let incorrect_root = 123456789;

        let _ = main(
            default_pub_key,
            default_sig,
            default_msg_hash_u8_array,
            incorrect_root,
            default_path_indecies,
            default_path_elements
        );
    }

    #[test(should_fail)]
    fn test_main_fail_scenario_path_indecies() {
        let incorrect_path_indecies = 4;

        let _ = main(
            default_pub_key,
            default_sig,
            default_msg_hash_u8_array,
            default_root,
            incorrect_path_indecies,
            default_path_elements
        );
    }

    #[test(should_fail)]
    fn test_main_fail_scenario_path_elements() {
        let  incorrect_path_elements = [
            9479145765164306604898661246306912585240247746526471519759854195178979516700,
            10821577188404079746999828440545293402557390793255312676266883079953085672921,
            10266675050323606453909836805900148358798034671050728166354968531595868722006,
            8575350884931261137867066738147375482425232494266355398216179294178508866708,
            2
        ];

        let _ = main(
            default_pub_key,
            default_sig,
            default_msg_hash_u8_array,
            default_root,
            default_path_indecies,
            incorrect_path_elements
        );
    }

    #[test]
    fn check_commitment() {
        let address_from = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        let correct_commitment = 0x1dfaa26abfd0ff9a17bb7c0bf15891ad06cad4991500b211a8edcc9a2a90fca6;

        let msg_hash = default_msg_hash_u8_array.as_field_array();
        let commitment = compute_commitment(address_from, msg_hash);

        assert_eq(commitment, correct_commitment);
    }
}
