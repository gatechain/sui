/// This example demonstrates a basic use of a shared greeting.
/// Rules:
/// - anyone can create and share a Greeting object
/// - everyone can update the text of the Greeting object
module dex_test::dex {
  use std::string;
  use sui::dex::{Token, create_token, new_liquidity_pool_internal_impl};
 
  /// API call that creates a globally shared Greeting object initialized with "Hello world!"
  public fun new_liquidity_pool(ctx: &mut TxContext) { 
    let tokena = create_token("tokena", "TOKEN_A");
    let tokenb = create_token("tokenb", "TOKEN_B");

    new_liquidity_pool_internal_impl(tokena,tokenb);
  }
}