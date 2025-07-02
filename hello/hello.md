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
echo 'aztec = { git = "https://github.com/AztecProtocol/aztec-packages/", tag = "v0.87.9", directory = "noir-projects/aztec-nr/aztec" }' >> Nargo.toml
```

```bash
# Replace src/main.nr with empty Aztec contract
echo 'use dep::aztec::macros::aztec; // import aztec macro for use

#[aztec] // use macro for contract
pub contract Hello {
  // imports, storage struct, and functions go here
}' > src/main.nr
```

### Division example

For demonstration purposes we'll show an implementation of division that is efficient for proving in private, but has an extra cost in public.

Inside the empty contract, we'll add the same function as public and private; outside will have the helper function.

```rust
#[aztec]
pub contract Hello {
    use crate::divide; // Noir helper function outside of contract

    // import function types
    use dep::aztec::macros::functions::{private, public};

    #[private] // use macro to wrap for private execution
    fn div_prv(dividend: u32, divisor: u32) -> u32 {
        //Safety: constrain after
        let (quotient, remainder) = unsafe { divide(dividend, divisor) };
        assert(quotient * divisor + remainder == dividend);
        quotient
    }

    #[public] // use macro to wrap for public execution
    fn div_exe(dividend: u32, divisor: u32) -> u32 {
        let (quotient, remainder) = divide(dividend, divisor);
        quotient
    }
} // contract Hello

// iterative divide function
pub unconstrained fn divide(dividend: u32, divisor: u32) -> (u32, u32) {
    let mut quotient: u32 = 0;
    let mut remainder: u32 = dividend;
    if divisor == 0 {
        (0, 0)
    } else {
        while remainder >= divisor {
            remainder = remainder - divisor;
            quotient = quotient + 1;
        }
        (quotient, remainder)
    }
}
```

## Understanding performance

Since private functions are executed client side and the proof of execution is used to advance private state, the size of the circuit is important. The size of a circuit is measured in gates.

Public functions are executed as part of the protocol, so the total cost of operations is important, which is measured in gas.

We can compile and then calculate the gates required for the private function, `div_prv`. To see gas for the public function, we will deploy the contract and call `div_exe`.

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
make gate-flamegraph div_prv
```

In the terminal you'll see: `Opcode count: 775, Total gates by opcodes: 5197, Circuit size: 5962`

Also go to the URL in the command output to see the gate count total, and of each sub-section. The exported .svg file is in the `target` directory.

### Unconstrained cost in private

To assess the cost of the unconstrained function in private, lets replace its call with a result directly, eg `(2, 2)`

```rust
    #[private] // use macro to wrap for private execution
    fn div_prv(dividend: u32, divisor: u32) -> u32 {
        //Safety: constrain after
        let (quotient, remainder) = (2, 2); //unsafe { divide(dividend, divisor) };
        assert(quotient * divisor + remainder == dividend);
        quotient
    }

```

Now calculating the gates flamegraph again:
```bash
make gate-flamegraph div_prv
```

In the terminal you'll see the same counts: `Opcode count: 775, Total gates by opcodes: 5197, Circuit size: 5962`

That is, the unconstrained function does NOT contribute to gate count in the private function. So the result from this unconstrained function must then be verified in the calling constrained function (via `assert`).

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

- `no-init` is specified because we do not have or need a constructor/`initializer` for this example
- The last param requests the deployed contract address be aliased to `hello`

### Command summary script

For convenience/reference, these commands are consolidated in a script. To see them:
```bash
./run.sh --help
```

### Showing gas cost for a transaction

With the sandbox running and contract deployed (see earlier section), we can now interact with the public function:

```bash
./run.sh hello-fn div_exe 8 3
```

```bash
Transaction has been mined
 Tx fee: 39680550
 ...
```

Lets assess the cost of the unconstrained function in public by replacing the call with a result:

```rust
    let (quotient, remainder) = (2, 2); // divide(dividend, divisor);
```

Compiling, deploying, then calling:

```bash
make
./run.sh hello-deploy
./run.sh hello-fn div_exe 8 3
```

The result will show a lower gas cost:
```bash
Transaction has been mined
 Tx fee: 33770160
```

That is, the unconstrained function call from public contributes to the cost.

### Comparison

The above example highlights that coding things well in private may have unexpected costs if used in public.

Another example of this is in the use of memory. This is cheaper in private circuits (witness values) and expensive in public (operations to read across different memory locations).

## Further use

### Testing output

For a quick sneak peak into testing, see the functions after the Noir divide function: `setup()` and `test_funcs()`. Notice the more explicity way of calling a function from a private or public context.

Tests are simply run with the command: `aztec test`

Under the hood this does two things:
- Starts a Testing eXecution Environment - `aztec start --txe --port=8081`
- Runs nargo tests pointing to the txe as an oracle - `nargo test --silence-warnings --pedantic-solving --oracle-resolver http://127.0.0.1:8081`

We'll modify the second command to show the `println` output:
- Start TXE - `aztec start --txe --port=8081` (in a separate terminal)
- Test - `nargo test --oracle-resolver http://127.0.0.1:8081 --show-output`

### Profile gate count

To see a breakdown of proving times and gate counts per inner-circuit:

```bash
./run.sh gate-profile div_prv 8 3
```

This command expects the contract in `hello.nr` to be deployed, and the contract address aliased to `hello`.

This uses the deployed contract to provide a breakdown of time and gates for each inner function. This will become useful when comparing calls into contexts.


## Further reading

- For more about optimisation, see [Thinking in Circuits](https://noir-lang.org/docs/explainers/explainer-writing-noir), and [aztec-examples]().
- To see a side-by-side comparison with Rust, see [noir_by_example](https://github.com/noir-lang/noir-examples/tree/master/noir_by_example#readme).
