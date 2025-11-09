// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[allow(unused_const)]
module sui::dex;
use std::string;
/// A coin of type `T` worth `value`. Transferable and storable
public struct Token {
    name: string::String,
    symbol: string::String,
}

public fun create_token(name: string::String, symbol: string::String): Token {
        Token { name, symbol }
}

public native fun new_liquidity_pool_internal_impl(tokena: Token, tokenb: Token);
