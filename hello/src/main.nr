use dep::aztec::macros::aztec;

#[aztec]
pub contract Hello {

    use dep::aztec::macros::functions::{private, public, utility};
    use dep::aztec::prelude::{AztecAddress, FunctionSelector};

    #[private]
    pub fn mul_8_exe(num: u32) -> u32 {
        num << 3
    }

    #[private]
    pub fn mul_8_prv(num: u32) -> u32 {
        num * 8
    }

    #[private]
    fn math_ops_3_prv(num: u32) -> u32 {
        let mut result = num;
        result = context
            .call_private_function(
                context.this_address(),
                FunctionSelector::from_signature("mul_8_prv"),
                [result as Field],
            )
            .get_preimage();
        result = context
            .call_private_function(
                context.this_address(),
                FunctionSelector::from_signature("mul_8_prv"),
                [result as Field],
            )
            .get_preimage();
        result = context
            .call_private_function(
                context.this_address(),
                FunctionSelector::from_signature("mul_8_prv"),
                [result as Field],
            )
            .get_preimage();
        result
    }

}
