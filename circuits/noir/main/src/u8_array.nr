use dep::std::field::bytes32_to_field;

global WORD_LEN = 32;

struct U8Array<N> {
    arr: [u8; N]
}

impl<N> U8Array<N> {
    pub fn as_field_array(self) -> [Field; N] {
        self.arr.map(|x: u8| -> Field x as Field)
    }

    pub fn as_array(self) -> [u8; N] {
        self.arr
    }

    pub fn as_field(self) -> Field {
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

mod tests {
    use crate::u8_array::U8Array;

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
}
