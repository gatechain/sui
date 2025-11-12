// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Example module for DEX operations - can be deployed to testnet/mainnet
module dex_test::dex_example {
    use sui::dex::{Self, Pool, Order, OrderCap};

    // Example coin types for trading
    public struct USDC has drop {}
    public struct BTC has drop {}

    // ==================== Initialization ====================

    /// Create and share a new BTC/USDC trading pool
    public entry fun create_btc_usdc_pool(ctx: &mut TxContext) {
        let pool = dex::create_pool<BTC, USDC>(
            100,    // tick_size: prices must be multiples of 100
            1,      // min_order_size: minimum 1 unit
            ctx
        );
        dex::share_pool(pool);
    }

    /// Create and share a custom trading pool
    public entry fun create_custom_pool<BaseAsset, QuoteAsset>(
        tick_size: u64,
        min_order_size: u64,
        ctx: &mut TxContext
    ) {
        let pool = dex::create_pool<BaseAsset, QuoteAsset>(
            tick_size,
            min_order_size,
            ctx
        );
        dex::share_pool(pool);
    }

    // ==================== Order Operations ====================

    /// Place a bid (buy) order
    public entry fun place_bid<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        price: u64,
        quantity: u64,
        expire_timestamp: u64,
        ctx: &mut TxContext
    ) {
        let (order, order_cap) = dex::place_order(
            pool,
            price,
            quantity,
            true,  // is_bid
            expire_timestamp,
            ctx
        );
        
        // Transfer order and cap to sender
        transfer::public_transfer(order, ctx.sender());
        transfer::public_transfer(order_cap, ctx.sender());
    }

    /// Place an ask (sell) order
    public entry fun place_ask<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        price: u64,
        quantity: u64,
        expire_timestamp: u64,
        ctx: &mut TxContext
    ) {
        let (order, order_cap) = dex::place_order(
            pool,
            price,
            quantity,
            false,  // is_bid
            expire_timestamp,
            ctx
        );
        
        // Transfer order and cap to sender
        transfer::public_transfer(order, ctx.sender());
        transfer::public_transfer(order_cap, ctx.sender());
    }

    /// Cancel an existing order
    public entry fun cancel<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        order: Order,
        order_cap: OrderCap,
        ctx: &TxContext
    ) {
        dex::cancel_order(pool, order, order_cap, ctx);
    }

    // ==================== Batch Operations ====================

    /// Place multiple bid orders at different prices
    public entry fun place_multiple_bids<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        prices: vector<u64>,
        quantities: vector<u64>,
        expire_timestamp: u64,
        ctx: &mut TxContext
    ) {
        let len = prices.length();
        assert!(len == quantities.length(), 0);
        
        let mut i = 0;
        while (i < len) {
            let price = *prices.borrow(i);
            let quantity = *quantities.borrow(i);
            
            let (order, order_cap) = dex::place_order(
                pool,
                price,
                quantity,
                true,
                expire_timestamp,
                ctx
            );
            
            transfer::public_transfer(order, ctx.sender());
            transfer::public_transfer(order_cap, ctx.sender());
            i = i + 1;
        };
    }

    /// Place multiple ask orders at different prices
    public entry fun place_multiple_asks<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        prices: vector<u64>,
        quantities: vector<u64>,
        expire_timestamp: u64,
        ctx: &mut TxContext
    ) {
        let len = prices.length();
        assert!(len == quantities.length(), 0);
        
        let mut i = 0;
        while (i < len) {
            let price = *prices.borrow(i);
            let quantity = *quantities.borrow(i);
            
            let (order, order_cap) = dex::place_order(
                pool,
                price,
                quantity,
                false,
                expire_timestamp,
                ctx
            );
            
            transfer::public_transfer(order, ctx.sender());
            transfer::public_transfer(order_cap, ctx.sender());
            i = i + 1;
        };
    }
}

