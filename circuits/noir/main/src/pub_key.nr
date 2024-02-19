use dep::std::ecdsa_secp256k1::verify_signature;
use dep::std::hash::keccak256;
use crate::u8_array::{U8Array, WORD_LEN};

global SIGNATURE_LEN = 64; // r + s
global FLATTEN_PUB_KEY_LEN = 64; // x + y
global ADDRESS_LEN = 20;

type U8Word = [u8; WORD_LEN];
type RawSignature = [u8; SIGNATURE_LEN];

struct PubKey {
    x: U8Word,
    y: U8Word
}

impl PubKey {
    pub fn get_address(self) -> U8Array<ADDRESS_LEN> {
        let pk_hash = keccak256(self.as_u8_array(), FLATTEN_PUB_KEY_LEN);

        let mut address = U8Array { arr: [0; ADDRESS_LEN] };

        // Take last 20 bytes
        for i in 12..WORD_LEN {
            address.arr[i - 12] = pk_hash[i];
        }

        address
    }

    pub fn as_u8_array(self) -> [u8; FLATTEN_PUB_KEY_LEN] {
        let mut arr = [0; FLATTEN_PUB_KEY_LEN];

        for i in 0..WORD_LEN {
            arr[i] = self.x[i];
            arr[i + WORD_LEN] = self.y[i];
        }

        arr
    }

    pub fn is_sig_valid_for_msg(self, sig: RawSignature, msg_hash: U8Word) -> bool {
        verify_signature(self.x, self.y, sig, msg_hash)
    }
}

mod tests {
    use crate::pub_key::{U8Word, PubKey, RawSignature};
    use crate::u8_array::U8Array;

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
}
