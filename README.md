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
