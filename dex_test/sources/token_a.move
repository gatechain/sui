// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Test Token A module
module dex_test::token_a {
    use sui::coin;

    /// One-time witness for TOKEN_A
    public struct TOKEN_A has drop {}

    /// Initialize TOKEN_A currency
    fun init(witness: TOKEN_A, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            9,
            b"TOKENA",
            b"Token A",
            b"Test token A for DEX",
            option::none(),
            ctx
        );
        
        // Transfer treasury to sender
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }
}

