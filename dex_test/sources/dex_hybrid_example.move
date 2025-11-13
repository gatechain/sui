// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Example usage of dex_hybrid for CLI testing
module dex_test::dex_hybrid_example {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::dex_hybrid;
    use dex_test::token_a::TOKEN_A;
    use dex_test::token_b::TOKEN_B;

    // ==================== Module Witness ====================
    
    /// One-time witness for module initialization
    public struct DEX_HYBRID_EXAMPLE has drop {}

    // ==================== Initialization ====================

    /// Initialize module (called once on publish)
    fun init(_witness: DEX_HYBRID_EXAMPLE, _ctx: &mut TxContext) {
        // Module initialization
        // Note: TOKEN_A and TOKEN_B treasuries are created automatically 
        // when their respective modules are published
    }

    // ==================== Setup Functions ====================

    /// Create a trading pool (Step 1)
    /// Example: sui client call --function create_test_pool
    public entry fun create_test_pool(ctx: &mut TxContext) {
        dex_hybrid::create_pool<TOKEN_A, TOKEN_B>(
            1_000_000,      // min_order_size: 0.001 TOKEN_A
            10_000,         // tick_size: 0.00001 (price precision)
            ctx
        );
    }

    /// Create SUI/TOKEN_A pool
    public entry fun create_sui_token_pool(ctx: &mut TxContext) {
        dex_hybrid::create_pool<SUI, TOKEN_A>(
            1_000_000,      // min_order_size: 0.001 SUI
            10_000,         // tick_size
            ctx
        );
    }

    // ==================== Minting Functions ====================

    /// Mint TOKEN_A for testing
    public entry fun mint_token_a(
        treasury_cap: &mut coin::TreasuryCap<TOKEN_A>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Mint TOKEN_B for testing
    public entry fun mint_token_b(
        treasury_cap: &mut coin::TreasuryCap<TOKEN_B>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    // ==================== Trading Functions ====================

    /// Place a buy order (buy TOKEN_A with TOKEN_B)
    /// Example: Buy 10 TOKEN_A at price 1.5 TOKEN_B per TOKEN_A
    public entry fun place_buy_order(
        pool: &mut dex_hybrid::Pool<TOKEN_A, TOKEN_B>,
        price: u64,           // e.g., 1_500_000_000 = 1.5 TOKEN_B (9 decimals)
        quantity: u64,        // e.g., 10_000_000_000 = 10 TOKEN_A (9 decimals)
        payment: Coin<TOKEN_B>,
        ctx: &mut TxContext
    ) {
        let (token_a_received, token_b_change) = dex_hybrid::place_limit_order(
            pool,
            price,
            quantity,
            true,  // is_bid = true (buy order)
            payment,
            ctx
        );
        
        // Transfer received tokens to sender
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(token_a_received, sender);
        transfer::public_transfer(token_b_change, sender);
    }

    /// Place a sell order (sell TOKEN_A for TOKEN_B)
    /// Example: Sell 10 TOKEN_A at price 1.5 TOKEN_B per TOKEN_A
    public entry fun place_sell_order(
        pool: &mut dex_hybrid::Pool<TOKEN_A, TOKEN_B>,
        price: u64,           // e.g., 1_500_000_000 = 1.5 TOKEN_B
        quantity: u64,        // e.g., 10_000_000_000 = 10 TOKEN_A
        ctx: &mut TxContext
    ) {
        // For sell orders, we need to pass an empty coin as payment
        // In a full implementation, the seller would escrow TOKEN_A separately
        let payment_b = coin::zero<TOKEN_B>(ctx);
        
        let (token_a_received, token_b_received) = dex_hybrid::place_limit_order(
            pool,
            price,
            quantity,
            false,  // is_bid = false (sell order)
            payment_b,
            ctx
        );
        
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(token_a_received, sender);
        transfer::public_transfer(token_b_received, sender);
    }

    /// Place a market buy order (buy at best available price)
    public entry fun market_buy(
        pool: &mut dex_hybrid::Pool<TOKEN_A, TOKEN_B>,
        quantity: u64,
        max_price: u64,       // Maximum price willing to pay
        payment: Coin<TOKEN_B>,
        ctx: &mut TxContext
    ) {
        let (token_a_received, token_b_change) = dex_hybrid::place_limit_order(
            pool,
            max_price,
            quantity,
            true,
            payment,
            ctx
        );
        
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(token_a_received, sender);
        transfer::public_transfer(token_b_change, sender);
    }

    /// Cancel an order
    public entry fun cancel_order(
        pool: &mut dex_hybrid::Pool<TOKEN_A, TOKEN_B>,
        order_id: u64,
        ctx: &TxContext
    ) {
        dex_hybrid::cancel_order(pool, order_id, ctx);
    }

    // ==================== Query Functions ====================

    /// Get best bid and ask prices
    public fun get_spread(
        pool: &dex_hybrid::Pool<TOKEN_A, TOKEN_B>
    ): (u64, u64) {
        dex_hybrid::get_best_prices(pool)
    }

    /// Get order book depth at specific price
    public fun get_depth(
        pool: &dex_hybrid::Pool<TOKEN_A, TOKEN_B>,
        price: u64,
        is_bid: bool
    ): u64 {
        dex_hybrid::get_depth_at_price(pool, price, is_bid)
    }

    /// Get order information
    public fun get_order(
        pool: &dex_hybrid::Pool<TOKEN_A, TOKEN_B>,
        order_id: u64
    ): (u64, u64, u64, bool, address) {
        dex_hybrid::get_order_info(pool, order_id)
    }
}

