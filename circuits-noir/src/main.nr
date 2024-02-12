use dep::std;
use std::field::{bytes32_to_field};
use std::ecdsa_secp256k1::{verify_signature};
use std::hash::keccak256;

mod merkle_tree;
use merkle_tree::{compute_merkle_root, mimc_sponge};

global WORD_LEN = 32;
global LEVELS: Field = 5; // Depth of the tree
global FLATTEN_PUB_KEY_LEN = 64; // x + y
global SIGNATURE_LEN = 64; // r + s
global ADDRESS_LEN = 20;

type RawSignature = [u8; SIGNATURE_LEN];
type U8Word = [u8; WORD_LEN];
type TREE_HASH_PATH = [Field; LEVELS];

struct U8Array<N> {
    arr: [u8; N]
}

impl<N> U8Array<N> {
    fn as_field_array(self) -> [Field; N] {
        self.arr.map(|x: u8| -> Field x as Field)
    }

    fn as_array(self) -> [u8; N] {
        self.arr
    }

    fn as_field(self) -> Field {
        let initial_length = self.arr.len();
        assert(initial_length.lt(WORD_LEN + 1), "U8Array: array length gt 32");

        let mut bytes_arr = [0; WORD_LEN];
        for i in 0..initial_length {
            let p = (i + 1);
            let j = WORD_LEN - p;
            let k = initial_length - p;
            bytes_arr[j] = self.arr[k];
        }

        bytes32_to_field(bytes_arr)
    }
}

struct PubKey {
    x: U8Word,
    y: U8Word
}

impl PubKey {
    fn get_address(self) -> U8Array<ADDRESS_LEN> {
        let pk_hash = keccak256(self.as_u8_array(), FLATTEN_PUB_KEY_LEN);

        let mut address = U8Array {
            arr: [0; ADDRESS_LEN],
        };


        // Take last 20 bytes
        for i in 12..WORD_LEN {
            address.arr[i - 12] = pk_hash[i];
        }

        address
    }

    fn as_u8_array(self) -> [u8; FLATTEN_PUB_KEY_LEN] {
        let mut arr = [0; FLATTEN_PUB_KEY_LEN];

        for i in 0..WORD_LEN {
            arr[i] = self.x[i];
            arr[i + WORD_LEN] = self.y[i];
        }

        arr
    }

    fn is_sig_valid_for_msg(self, sig: RawSignature, msg_hash: U8Word) -> bool {
        verify_signature(self.x, self.y, sig, msg_hash)
    }

}

fn compute_commitment(addr: Field, msg_hash: [Field; WORD_LEN]) -> Field {
    let mut commitment_array = [0; WORD_LEN + 1];

    commitment_array[0] = addr;
    for i in 1..(msg_hash.len() + 1) {
        commitment_array[i] = msg_hash[i - 1];
    }

    let commitment: [Field; 1] = mimc_sponge(commitment_array, 0);
    commitment[0]
}

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
    let user_leaf: [Field; 1] = mimc_sponge([addr], 0);
    let user_leaf = user_leaf[0];

    // Verify that address in Merkle Trie
    let result_root = compute_merkle_root(user_leaf, path_indexes, hash_path);
    assert_eq(result_root, root, "The roots don't match");

    // Return commitment
    compute_commitment(addr, msg_hash.as_field_array())
}

mod tests {
    use crate::{U8Word, U8Array, PubKey, RawSignature, main, compute_commitment};

    global default_msg_hash: U8Word = [
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

    global default_sig: RawSignature = [
            202, 253, 131, 117, 218, 12, 92, 139, 45, 202, 191,
            23, 123, 110, 15, 26, 199, 178, 234, 37, 148, 148,
            94, 189, 132, 104, 159, 85, 202, 82, 6, 91, 120,
            69, 87, 70, 11, 174, 63, 133, 162, 246, 222, 140,
            123, 158, 141, 3, 254, 120, 46, 196, 212, 229, 75,
            14, 101, 115, 209, 33, 115, 10, 145, 53
        ];

    #[test]
    fn test_verify_signature_vlaid() {
        assert(default_pub_key.is_sig_valid_for_msg(default_sig, default_msg_hash));
    }

    #[test(should_fail)]
    fn test_verify_signature_invalid_sig() {
        let invalid_sig = [
            20, 253, 131, 117, 218, 12, 92, 139, 45, 202, 191,
            23, 123, 110, 15, 26, 199, 178, 234, 37, 148, 148,
            94, 189, 132, 104, 159, 85, 202, 82, 6, 91, 120,
            69, 87, 70, 11, 174, 63, 133, 162, 246, 222, 140,
            123, 158, 141, 3, 254, 120, 46, 196, 212, 229, 75,
            14, 101, 115, 209, 33, 115, 10, 145, 53
        ];

        assert(default_pub_key.is_sig_valid_for_msg(invalid_sig, default_msg_hash));
    }

    #[test(should_fail)]
    fn test_verify_signature_invalid_hash() {
        let msg_hash: U8Word = [
            1, 207, 71, 217, 145, 255, 62, 188,
            249, 9, 45, 82, 88, 164, 226, 63,
            176, 171, 77, 186, 72, 238, 53, 94,
            195, 131, 67, 182, 187, 42, 212, 140
        ];

        assert(default_pub_key.is_sig_valid_for_msg(default_sig, msg_hash));
    }

    #[test(should_fail)]
    fn test_verify_signature_invalid_pk() {
        let pub_key = PubKey {
            x: [
                130, 24, 83, 91, 84, 16, 93, 74,
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

        assert(pub_key.is_sig_valid_for_msg(default_sig, default_msg_hash));
    }

    #[test]
    fn test_get_address_return_correct_value_as_U8Array() {
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        let address_u8 = [
            243, 159, 214, 229, 26, 173, 136, 246, 244, 206, 106, 184, 130, 114, 121, 207, 255, 185, 34, 102
        ];

        assert_eq(address_u8, default_pub_key.get_address().as_array());
    }

    #[test]
    fn test_get_address_return_correct_value_as_Field() {
        let correctAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        assert_eq(correctAddress, default_pub_key.get_address().as_field());
    }

    #[test(should_fail)]
    fn test_length_gt_32_as_field() {
        let u8_arr: U8Array<33> = U8Array {
            arr: [
                24, 148, 62, 131, 205, 204, 28, 18,
                29, 55, 150, 65, 231, 146, 244, 25,
                184, 168, 40, 188, 155, 34, 10, 78,
                78, 170, 171, 166, 237, 21, 227, 177, 1
            ]
        };

        let _ = u8_arr.as_field();
    }

    #[test]
    fn test_convert_u8_to_field_32_bytes() {
        let u8_arr: U8Array<32> = U8Array {
            arr: [
                24, 148, 62, 131, 205, 204, 28, 18,
                29, 55, 150, 65, 231, 146, 244, 25,
                184, 168, 40, 188, 155, 34, 10, 78,
                78, 170, 171, 166, 237, 21, 227, 177
            ]
        };

        assert_eq(
            u8_arr.as_field(), 11117433193285094245873819303193981801601056115958843892440545852012495233969
        );
    }

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
