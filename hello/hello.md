# Coding for Execution vs Proving

In this intro example you will:

- Create an Aztec contract from scratch
- Add Aztec dependencies and macros
- Appreciate different function types/considerations
- Measure proving cost
- Run a local node, deploy/interact with contract

## Self Setup

The steps in this section explain how to recreate a project like this from scratch.

### Create project files and first contract

The flow with Noir is much like that of Rust.

```bash
# Create project dir and boilerplate files
aztec-nargo new --contract hello
```

```bash
# Add Aztec dependency to `hello/Nargo.toml`
cd hello
echo 'aztec = { git = "https://github.com/AztecProtocol/aztec-packages/", tag = "v0.87.8", directory = "noir-projects/aztec-nr/aztec" }' >> Nargo.toml
```

```bash
# Replace src/main.nr with empty Aztec contract
echo 'use dep::aztec::macros::aztec; // import aztec macro for use

#[aztec] // use macro for contract
pub contract Hello {
  // imports, storage struct, and functions go here
}' > src/main.nr
```

### Add a private function

Inside the empty contract, add the following functions and their requisite macro imports:

```rust
    // ...
    // import function types
    use dep::aztec::macros::functions::{private, public};

    #[private] // use macro to wrap for private execution
    fn mul_8_prv(num: u32) -> u32 {
        num * 8 // more efficient for proving
    }

    #[public] // use macro to wrap for public execution
    fn mul_8_exe(num: u32) -> u32 {
        num << 3 // more efficient for execution
    }

// ...
```

## Understanding performance

Since private functions are executed client side and the proof of execution is used to advance private state, the size of the circuit is important. The size of a circuit is measured in gates.

Public functions are executed as part of the protocol, so the total cost of operations is important, which is measured in gas.

We can compile and then calculate the gates required for this private function.

## Building the project
### Compile the contract

For simplicity this project uses make, where `make build` calls `aztec-nargo compile`. Build is the default make target so for convenience simply compile the contract with:

```bash
# From directory with Markefile & Nargo.toml
make
```

### Showing gate counts in a flamegraph

The gate flamegraph of a specific function can be calculate and presented by passing the function name to:

```bash
make gate-flamegraph <function-name>
```

eg: `make gate-flamegraph mul_8_prv`

Go to the URL in the command output to see the gate count total, and of each sub-section. The exported .svg file is in the `target` directory.

## Using the project
### Deploy contract to Aztec dev node

First we'll run a local dev environment, aka "sandbox", which includes:

- an Aztec dev node
- a Private eXecution Environment (PXE)

Both can be started together in a terminal with: `aztec start --sandbox`

We will now use the `aztec-wallet` to interact with them.

```bash
# Register test account contract addresses from sandbox, into the pxe
aztec-wallet import-test-accounts
aztec-wallet get-alias accounts # show account contract aliases -> addresses
```

Use the test account aliased to, `test0`, to deploy the compiled contract:

```bash
aztec-wallet deploy --no-init target/hello-Hello.json --from test0 --alias hello
```

Note:

- `no-init` is specified because we do not have or need a constractor/`initializer` for this example
- The last param requests the deployed contract address be aliased to `hello`

### Command summary script

For convenience/reference, these commands are consolidated in a script. To see them:
```bash
./run.sh --help
```

### Profile gate count

To see a breakdown of proving times and gate counts per inner-circuit:

```bash
./run.sh gate-profile mul_8_prv 8
```

This command expects the contract in `hello.nr` to be deployed, and the contract address aliased to `hello`.

This uses the deployed contract to provide a breakdown of time and gates for each inner function. This will become useful when comparing 

## Compare implementations



## Calling private functions



## Further reading

- For more about optimisation, see [Thinking in Circuits](https://noir-lang.org/docs/explainers/explainer-writing-noir), and [aztec-examples]().
- To see a side-by-side comparison with Rust, see [noir_by_example](https://github.com/noir-lang/noir-examples/tree/master/noir_by_example#readme).
