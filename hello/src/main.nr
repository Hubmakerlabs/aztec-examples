use dep::aztec::macros::aztec;

#[aztec]
pub contract Hello {
    use crate::divide;

    // import function types
    use dep::aztec::macros::functions::{private, public};

    #[private] // use macro to wrap for private execution
    fn div_prv(dividend: u32, divisor: u32) -> u32 {
        //Safety: constrain after
        let (quotient, remainder) = unsafe { divide(dividend, divisor) };
        assert(quotient * divisor + remainder == dividend);
        quotient
    } // tx fee: 567952000 (with unconstrained divide)

    #[public] // use macro to wrap for public execution
    fn div_exe(dividend: u32, divisor: u32) -> u32 {
        let (quotient, remainder) = divide(dividend, divisor);
        quotient
    } // tx fee: 1945438440 (with unconstrained divide)

}

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

//////TESTING//////
use dep::aztec::prelude::AztecAddress;
use dep::aztec::test::helpers::test_environment::TestEnvironment;

#[test]
unconstrained fn test_funcs() {
    let (env, hello_contract_address, user) = setup();
    env.advance_block_by(1);

    // let result = env.call_private(contract_address, Hello::interface().math_ops_3_prv(8));
    let result = Hello::at(hello_contract_address).div_prv(8, 3).call(&mut env.private());
    println(result); // can use println in txe tests, but not aztec functions called by tests. debug_log doesn't work.
    assert(result == 2, "Expected 2 but got {result}");

    let result = Hello::at(hello_contract_address).div_exe(8, 3).call(&mut env.public());
    println(result); // can use println in txe tests, but not aztec functions called by tests. debug_log doesn't work.
    assert(result == 2, "Expected 2 but got {result}");
}

pub unconstrained fn setup() -> (&mut TestEnvironment, AztecAddress, AztecAddress) {
    // Setup env, generate keys
    let mut env = TestEnvironment::new();
    let user = env.create_account_contract(1);

    // Start the test in the account contract address
    env.impersonate(user);

    // Deploy token contract
    let hello_contract = env.deploy_self("Hello").without_initializer();
    let hello_contract_address = hello_contract.to_address();

    (&mut env, hello_contract_address, user)
}
