use dep::mimc_sponge::mimc_sponge;

pub fn compute_merkle_root<N>(leaf: Field, index: Field, hash_path: [Field; N]) -> Field {
    let n = hash_path.len();
    let index_bits = index.to_le_bits(n as u32);
    let mut current = leaf;
    for i in 0..n {
        let path_bit = index_bits[i] as bool;
        let (hash_left, hash_right) = if path_bit {
            (hash_path[i], current)
        } else {
            (current, hash_path[i])
        };

        let digest: [Field; 1] = mimc_sponge([hash_left, hash_right], 0);
        current = digest[0];
    }
    current
}

#[test]
fn test_merkle_tree() {
    let root = 7378323513472991738372527896654445137493089583233093119951646841738120031371;

    let path = [
        9479145765164306604898661246306912585240247746526471519759854195178979516700,
        10821577188404079746999828440545293402557390793255312676266883079953085672921,
        10266675050323606453909836805900148358798034671050728166354968531595868722006,
        8575350884931261137867066738147375482425232494266355398216179294178508866708,
        18097266179879782427361438755277450939722755112152115227098348943187633376449
    ];
    let indexes = 0;
    let leaf = 11117433193285094245873819303193981801601056115958843892440545852012495233969;

    let res_root = compute_merkle_root(leaf, indexes, path);
    assert_eq(res_root, root);
}
