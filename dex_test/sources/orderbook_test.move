// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Test module for orderbook functionality
#[test_only]
module dex_test::orderbook_test {
    use sui::dex::{Self, Pool, Order, OrderCap};
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::test_utils;

    // Test coin types
    public struct USDC has drop {}
    public struct BTC has drop {}

    const USER1: address = @0xA;
    const USER2: address = @0xB;

    #[test]
    fun test_create_pool() {
        let mut scenario = ts::begin(USER1);
        
        // Create pool
        {
            let ctx = ts::ctx(&mut scenario);
            let pool = dex::create_pool<BTC, USDC>(
                100,  // tick_size: 100 (price must be multiples of 100)
                1,    // min_order_size: 1
                ctx
            );
            dex::share_pool(pool);
        };
        
        // Verify pool exists
        ts::next_tx(&mut scenario, USER1);
        {
            let pool = ts::take_shared<Pool<BTC, USDC>>(&scenario);
            assert!(dex::pool_total_orders(&pool) == 0, 0);
            assert!(dex::pool_next_order_id(&pool) == 0, 1);
            ts::return_shared(pool);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_place_bid_order() {
        let mut scenario = ts::begin(USER1);
        
        // Create pool
        {
            let ctx = ts::ctx(&mut scenario);
            let pool = dex::create_pool<BTC, USDC>(100, 1, ctx);
            dex::share_pool(pool);
        };
        
        // Place a bid order
        ts::next_tx(&mut scenario, USER1);
        {
            let mut pool = ts::take_shared<Pool<BTC, USDC>>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let (order, order_cap) = dex::place_order(
                &mut pool,
                50000,  // price
                10,     // quantity
                true,   // is_bid (buy)
                1000000000, // expire_timestamp
                ctx
            );
            
            // Verify order
            assert!(dex::order_price(&order) == 50000, 0);
            assert!(dex::order_quantity(&order) == 10, 1);
            assert!(dex::order_is_bid(&order) == true, 2);
            assert!(dex::order_id(&order) == 0, 3);
            
            // Verify pool state
            assert!(dex::pool_total_orders(&pool) == 1, 4);
            assert!(dex::get_best_bid(&pool) == 50000, 5);
            
            let (bid_qty, ask_qty, bid_levels, ask_levels) = dex::get_depth_summary(&pool);
            assert!(bid_qty == 10, 6);
            assert!(ask_qty == 0, 7);
            assert!(bid_levels == 1, 8);
            assert!(ask_levels == 0, 9);
            
            transfer::public_transfer(order, USER1);
            transfer::public_transfer(order_cap, USER1);
            ts::return_shared(pool);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_place_ask_order() {
        let mut scenario = ts::begin(USER1);
        
        // Create pool
        {
            let ctx = ts::ctx(&mut scenario);
            let pool = dex::create_pool<BTC, USDC>(100, 1, ctx);
            dex::share_pool(pool);
        };
        
        // Place an ask order
        ts::next_tx(&mut scenario, USER1);
        {
            let mut pool = ts::take_shared<Pool<BTC, USDC>>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let (order, order_cap) = dex::place_order(
                &mut pool,
                51000,  // price
                5,      // quantity
                false,  // is_bid (sell)
                1000000000, // expire_timestamp
                ctx
            );
            
            // Verify order
            assert!(dex::order_price(&order) == 51000, 0);
            assert!(dex::order_quantity(&order) == 5, 1);
            assert!(dex::order_is_bid(&order) == false, 2);
            
            // Verify pool state
            assert!(dex::get_best_ask(&pool) == 51000, 3);
            
            let (bid_qty, ask_qty, bid_levels, ask_levels) = dex::get_depth_summary(&pool);
            assert!(bid_qty == 0, 4);
            assert!(ask_qty == 5, 5);
            assert!(bid_levels == 0, 6);
            assert!(ask_levels == 1, 7);
            
            transfer::public_transfer(order, USER1);
            transfer::public_transfer(order_cap, USER1);
            ts::return_shared(pool);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_cancel_order() {
        let mut scenario = ts::begin(USER1);
        
        // Create pool
        {
            let ctx = ts::ctx(&mut scenario);
            let pool = dex::create_pool<BTC, USDC>(100, 1, ctx);
            dex::share_pool(pool);
        };
        
        // Place order
        ts::next_tx(&mut scenario, USER1);
        {
            let mut pool = ts::take_shared<Pool<BTC, USDC>>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let (order, order_cap) = dex::place_order(
                &mut pool,
                50000,
                10,
                true,
                1000000000,
                ctx
            );
            
            transfer::public_transfer(order, USER1);
            transfer::public_transfer(order_cap, USER1);
            ts::return_shared(pool);
        };
        
        // Cancel order
        ts::next_tx(&mut scenario, USER1);
        {
            let mut pool = ts::take_shared<Pool<BTC, USDC>>(&scenario);
            let order = ts::take_from_sender<Order>(&scenario);
            let order_cap = ts::take_from_sender<OrderCap>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            dex::cancel_order(
                &mut pool,
                order,
                order_cap,
                ctx
            );
            
            // Verify pool state after cancellation
            assert!(dex::get_best_bid(&pool) == 0, 0);
            let (bid_qty, ask_qty, _, _) = dex::get_depth_summary(&pool);
            assert!(bid_qty == 0, 1);
            assert!(ask_qty == 0, 2);
            
            ts::return_shared(pool);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_multiple_orders_same_price() {
        let mut scenario = ts::begin(USER1);
        
        // Create pool
        {
            let ctx = ts::ctx(&mut scenario);
            let pool = dex::create_pool<BTC, USDC>(100, 1, ctx);
            dex::share_pool(pool);
        };
        
        // Place multiple orders at same price
        ts::next_tx(&mut scenario, USER1);
        {
            let mut pool = ts::take_shared<Pool<BTC, USDC>>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let (order1, cap1) = dex::place_order(&mut pool, 50000, 10, true, 1000000000, ctx);
            transfer::public_transfer(order1, USER1);
            transfer::public_transfer(cap1, USER1);
            
            let (order2, cap2) = dex::place_order(&mut pool, 50000, 20, true, 1000000000, ctx);
            transfer::public_transfer(order2, USER1);
            transfer::public_transfer(cap2, USER1);
            
            // Verify aggregation at price level
            assert!(dex::get_level_quantity(&pool, 50000, true) == 30, 0);
            assert!(dex::get_level_order_count(&pool, 50000, true) == 2, 1);
            
            let (bid_qty, _, _, _) = dex::get_depth_summary(&pool);
            assert!(bid_qty == 30, 2);
            
            ts::return_shared(pool);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_query_functions() {
        let mut scenario = ts::begin(USER1);
        
        // Create pool
        {
            let ctx = ts::ctx(&mut scenario);
            let pool = dex::create_pool<BTC, USDC>(100, 1, ctx);
            dex::share_pool(pool);
        };
        
        // Place orders at multiple price levels
        ts::next_tx(&mut scenario, USER1);
        {
            let mut pool = ts::take_shared<Pool<BTC, USDC>>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            // Bids at different prices
            let (o1, c1) = dex::place_order(&mut pool, 50000, 10, true, 1000000000, ctx);
            let (o2, c2) = dex::place_order(&mut pool, 49900, 15, true, 1000000000, ctx);
            
            // Asks at different prices
            let (o3, c3) = dex::place_order(&mut pool, 50100, 8, false, 1000000000, ctx);
            let (o4, c4) = dex::place_order(&mut pool, 50200, 12, false, 1000000000, ctx);
            
            // Test best prices
            assert!(dex::get_best_bid(&pool) == 50000, 0);
            assert!(dex::get_best_ask(&pool) == 50100, 1);
            
            // Test depth summary
            let (bid_qty, ask_qty, bid_levels, ask_levels) = dex::get_depth_summary(&pool);
            assert!(bid_qty == 25, 2);
            assert!(ask_qty == 20, 3);
            assert!(bid_levels == 2, 4);
            assert!(ask_levels == 2, 5);
            
            // Test level queries
            assert!(dex::has_level(&pool, 50000, true) == true, 6);
            assert!(dex::has_level(&pool, 50500, true) == false, 7);
            assert!(dex::get_level_quantity(&pool, 49900, true) == 15, 8);
            assert!(dex::get_level_order_count(&pool, 50100, false) == 1, 9);
            
            // Clean up
            transfer::public_transfer(o1, USER1);
            transfer::public_transfer(c1, USER1);
            transfer::public_transfer(o2, USER1);
            transfer::public_transfer(c2, USER1);
            transfer::public_transfer(o3, USER1);
            transfer::public_transfer(c3, USER1);
            transfer::public_transfer(o4, USER1);
            transfer::public_transfer(c4, USER1);
            
            ts::return_shared(pool);
        };
        
        ts::end(scenario);
    }
}

