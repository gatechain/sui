// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Test Token B module
module dex_test::token_b {
    use sui::coin;

    /// One-time witness for TOKEN_B
    public struct TOKEN_B has drop {}

    /// Initialize TOKEN_B currency
    fun init(witness: TOKEN_B, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            9,
            b"TOKENB",
            b"Token B",
            b"Test token B for DEX",
            option::none(),
            ctx
        );
        
        // Transfer treasury to sender
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }
}

