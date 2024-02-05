use dep::std::ecdsa_secp256k1::{verify_signature};
use dep::std::merkle::{compute_merkle_root};
use dep::std::hash::{pedersen_hash, keccak256};

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

impl<T> U8Array<T> {
    fn as_field_array(self) -> [Field; T] {
        self.arr.map(|x: u8| -> Field x as Field)
    }

    fn as_array(self) -> [u8; T] {
        self.arr
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
        let mut arr:[u8; FLATTEN_PUB_KEY_LEN] = [0; FLATTEN_PUB_KEY_LEN];

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

fn compute_commitment(addr: [Field; ADDRESS_LEN], msg_hash: [Field; WORD_LEN]) -> Field {
    let mut commitment_array = [0; ADDRESS_LEN + WORD_LEN];

    for i in 0..ADDRESS_LEN {
        commitment_array[i] = addr[i];
    }

    for i in ADDRESS_LEN..commitment_array.len() {
        commitment_array[i] = msg_hash[i - ADDRESS_LEN];
    }

    pedersen_hash(commitment_array)
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
    assert(is_sig_valid);

    // Convert pk to address
    let addr = pub_key.get_address().as_field_array();

    // Get user leaf (hash of address)
    let user_leaf = pedersen_hash(addr);

    // Verify that address in Merkle Trie
    let result_root = compute_merkle_root(user_leaf, path_indexes, hash_path);
    assert_eq(result_root, root);

    // Return commitment
    compute_commitment(addr, msg_hash.as_field_array())
}

#[test]
fn test_verify_signature_vlaid() {
    let msg_hash: U8Word = [
        2, 207, 71, 217, 145, 255, 62, 188,
        249, 9, 45, 82, 88, 164, 226, 63,
        176, 171, 77, 186, 72, 238, 53, 94,
        195, 131, 67, 182, 187, 42, 212, 140
    ];

    let pub_key = PubKey {
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

    let sig: RawSignature = [
        202, 253, 131, 117, 218, 12, 92, 139, 45, 202, 191,
        23, 123, 110, 15, 26, 199, 178, 234, 37, 148, 148,
        94, 189, 132, 104, 159, 85, 202, 82, 6, 91, 120,
        69, 87, 70, 11, 174, 63, 133, 162, 246, 222, 140,
        123, 158, 141, 3, 254, 120, 46, 196, 212, 229, 75,
        14, 101, 115, 209, 33, 115, 10, 145, 53
    ];

    assert(pub_key.is_sig_valid_for_msg(sig, msg_hash));
}

#[test(should_fail)]
fn test_verify_signature_invalid_sig() {
    let msg_hash: U8Word = [
        2, 207, 71, 217, 145, 255, 62, 188,
        249, 9, 45, 82, 88, 164, 226, 63,
        176, 171, 77, 186, 72, 238, 53, 94,
        195, 131, 67, 182, 187, 42, 212, 140
    ];

    let pub_key = PubKey {
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

    let sig = [
        20, 253, 131, 117, 218, 12, 92, 139, 45, 202, 191,
        23, 123, 110, 15, 26, 199, 178, 234, 37, 148, 148,
        94, 189, 132, 104, 159, 85, 202, 82, 6, 91, 120,
        69, 87, 70, 11, 174, 63, 133, 162, 246, 222, 140,
        123, 158, 141, 3, 254, 120, 46, 196, 212, 229, 75,
        14, 101, 115, 209, 33, 115, 10, 145, 53
    ];

    assert(pub_key.is_sig_valid_for_msg(sig, msg_hash));
}

#[test(should_fail)]
fn test_verify_signature_invalid_hash() {
    let msg_hash: U8Word = [
        1, 207, 71, 217, 145, 255, 62, 188,
        249, 9, 45, 82, 88, 164, 226, 63,
        176, 171, 77, 186, 72, 238, 53, 94,
        195, 131, 67, 182, 187, 42, 212, 140
    ];

    let pub_key = PubKey {
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

    let sig: RawSignature = [
        202, 253, 131, 117, 218, 12, 92, 139, 45, 202, 191,
        23, 123, 110, 15, 26, 199, 178, 234, 37, 148, 148,
        94, 189, 132, 104, 159, 85, 202, 82, 6, 91, 120,
        69, 87, 70, 11, 174, 63, 133, 162, 246, 222, 140,
        123, 158, 141, 3, 254, 120, 46, 196, 212, 229, 75,
        14, 101, 115, 209, 33, 115, 10, 145, 53
    ];

    assert(pub_key.is_sig_valid_for_msg(sig, msg_hash));
}

#[test(should_fail)]
fn test_verify_signature_invalid_pk() {
    let msg_hash: U8Word = [
        2, 207, 71, 217, 145, 255, 62, 188,
        249, 9, 45, 82, 88, 164, 226, 63,
        176, 171, 77, 186, 72, 238, 53, 94,
        195, 131, 67, 182, 187, 42, 212, 140
    ];

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
    let sig: RawSignature = [
        202, 253, 131, 117, 218, 12, 92, 139, 45, 202, 191,
        23, 123, 110, 15, 26, 199, 178, 234, 37, 148, 148,
        94, 189, 132, 104, 159, 85, 202, 82, 6, 91, 120,
        69, 87, 70, 11, 174, 63, 133, 162, 246, 222, 140,
        123, 158, 141, 3, 254, 120, 46, 196, 212, 229, 75,
        14, 101, 115, 209, 33, 115, 10, 145, 53
    ];

    assert(pub_key.is_sig_valid_for_msg(sig, msg_hash));
}

#[test]
fn test_get_address_return_correct_value() {
    // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    let correctFlattenedPk = [243, 159, 214, 229, 26, 173, 136, 246, 244, 206, 106, 184, 130, 114, 121, 207, 255, 185, 34, 102];

    let pub_key = PubKey {
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

    assert_eq(correctFlattenedPk, pub_key.get_address().arr);
}
