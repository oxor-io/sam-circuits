### Getting Started

To set up the project and install all dependencies, run the following command:

```shell
npm install -D
```

Explore the available scripts in the `package.json` file. Some key scripts include:

- For the entire process from circuit compilation to verification with WASM:

  ```shell
  npm run circom:compile:wasm:witness:setup:prove:verify
  ```

- Generate a verifier contract using:

  ```shell
  npm run circom:verifier
  ```

- Generate calldata for a verifier contract with:

  ```shell
  npm run circom:calldata
  ```

### Testing

Execute the tests using:

```shell
npm run test
```

### Note

The implementation in both Circom and Noir is identical, with the exception of how commitments are calculated.

For Circom, the commitment is influenced by the number of registers (`k`). This is represented as `MiMCSponge([address, msgHash])`, where `msgHash` is of a length that matches the value of `k` specified in the parameters. On the other hand, in Noir, the commitment calculation is `mimc_sponge([address, msg_hash])`, with `msg_hash` consisting of 32 elements, each one byte in length.
