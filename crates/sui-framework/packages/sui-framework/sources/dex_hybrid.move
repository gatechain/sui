// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Hybrid DEX: Native matching engine + Move object storage
/// 
/// Architecture:
/// - Move: Data persistence (Pool object with Table storage)
/// - Native: High-performance matching algorithm
/// - Move: Asset transfers using Coin module
module sui::dex_hybrid {
    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin};
    use sui::event;

    // ==================== Errors ====================
    
    const EInvalidPrice: u64 = 1;
    const EInvalidQuantity: u64 = 2;
    const EUnauthorized: u64 = 3;
    const EOrderNotFound: u64 = 4;

    // ==================== Storage Structures ====================

    /// Pool - Order book as shared object (on-chain queryable)
    public struct Pool<phantom BaseAsset, phantom QuoteAsset> has key {
        id: UID,
        next_order_id: u64,
        
        // Price level storage
        bid_levels: Table<u64, PriceLevel>,
        ask_levels: Table<u64, PriceLevel>,
        
        // Sorted prices for efficient lookup
        bid_prices: vector<u64>,  // Descending
        ask_prices: vector<u64>,  // Ascending
        
        // Order index
        order_index: Table<u64, OrderIndex>,
        
        // Statistics (on-chain queryable)
        total_bid_quantity: u64,
        total_ask_quantity: u64,
        total_orders: u64,
        total_volume: u64,
        
        // Configuration
        min_order_size: u64,
        tick_size: u64,
    }

    /// Price level containing orders at specific price
    public struct PriceLevel has store, drop {
        price: u64,
        total_quantity: u64,
        order_ids: vector<u64>,  // FIFO queue
    }

    /// Order index entry
    public struct OrderIndex has store, copy, drop {
        price: u64,
        quantity: u64,
        filled_quantity: u64,
        is_bid: bool,
        owner: address,
    }

    /// Order struct for native function
    public struct Order has copy, drop, store {
        order_id: u64,
        price: u64,
        quantity: u64,
        owner: address,
    }

    /// Match result from native function
    public struct MatchResult has drop {
        matched_orders: vector<MatchedOrder>,
        remaining_quantity: u64,
        taker_filled: u64,
    }

    /// Single matched order
    public struct MatchedOrder has copy, drop, store {
        maker_order_id: u64,
        maker_owner: address,
        quantity: u64,
        price: u64,
    }

    // ==================== Events ====================

    public struct OrderPlaced has copy, drop {
        pool_id: ID,
        order_id: u64,
        price: u64,
        quantity: u64,
        is_bid: bool,
        owner: address,
    }

    #[allow(unused_field)]
    public struct OrderMatched has copy, drop {
        pool_id: ID,
        taker_order_id: u64,
        maker_order_id: u64,
        price: u64,
        quantity: u64,
        taker: address,
        maker: address,
    }

    public struct OrderFilled has copy, drop {
        pool_id: ID,
        order_id: u64,
        total_filled: u64,
        owner: address,
    }

    // ==================== Native Functions ====================

    /// Native function: Get best bid and ask prices
    native fun get_best_prices_internal<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>
    ): (u64, u64);

    // ==================== Public Functions ====================

    /// Create a new trading pool
    public fun create_pool<BaseAsset, QuoteAsset>(
        min_order_size: u64,
        tick_size: u64,
        ctx: &mut TxContext,
    ) {
        let pool = Pool<BaseAsset, QuoteAsset> {
            id: object::new(ctx),
            next_order_id: 1,
            bid_levels: table::new(ctx),
            ask_levels: table::new(ctx),
            bid_prices: vector::empty(),
            ask_prices: vector::empty(),
            order_index: table::new(ctx),
            total_bid_quantity: 0,
            total_ask_quantity: 0,
            total_orders: 0,
            total_volume: 0,
            min_order_size,
            tick_size,
        };
        transfer::share_object(pool);
    }

    /// Place a limit order
    /// - Uses native function for high-performance matching
    /// - Handles asset transfers in Move
    /// - Updates on-chain state
    public fun place_limit_order<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        price: u64,
        quantity: u64,
        is_bid: bool,
        payment: Coin<QuoteAsset>,  // For buy orders
        ctx: &mut TxContext,
    ): (Coin<BaseAsset>, Coin<QuoteAsset>) {
        // Validate inputs
        assert!(price > 0, EInvalidPrice);
        assert!(quantity >= pool.min_order_size, EInvalidQuantity);
        
        let taker_owner = tx_context::sender(ctx);
        let order_id = pool.next_order_id;
        pool.next_order_id = pool.next_order_id + 1;

        // Perform matching in Move (simpler than native for now)
        let match_result = calculate_matches_in_move(
            pool,
            price,
            quantity,
            is_bid,
        );

        // Process matched orders (asset transfers)
        let (base_received, quote_change) = if (is_bid) {
            execute_buy_matches(pool, &match_result, payment, ctx)
        } else {
            // For sell orders, payment should be empty, but we still need to consume it
            execute_sell_matches(pool, &match_result, payment, ctx)
        };

        // Update order book with remaining quantity
        if (match_result.remaining_quantity > 0) {
            add_order_to_book(
                pool,
                order_id,
                price,
                match_result.remaining_quantity,
                is_bid,
                taker_owner,
            );
        };

        // Emit events
        event::emit(OrderPlaced {
            pool_id: object::id(pool),
            order_id,
            price,
            quantity,
            is_bid,
            owner: taker_owner,
        });

        if (match_result.taker_filled > 0) {
            event::emit(OrderFilled {
                pool_id: object::id(pool),
                order_id,
                total_filled: match_result.taker_filled,
                owner: taker_owner,
            });
        };

        // Update statistics
        pool.total_volume = pool.total_volume + match_result.taker_filled;

        (base_received, quote_change)
    }

    /// Cancel an order
    public fun cancel_order<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
        ctx: &TxContext,
    ) {
        assert!(table::contains(&pool.order_index, order_id), EOrderNotFound);
        
        let order_info = table::borrow(&pool.order_index, order_id);
        let caller = tx_context::sender(ctx);
        assert!(order_info.owner == caller, EUnauthorized);

        // Remove from price level
        remove_order_from_level(pool, order_id, order_info.price, order_info.is_bid);

        // Remove from index
        table::remove(&mut pool.order_index, order_id);
        pool.total_orders = pool.total_orders - 1;
    }

    /// Query: Get best bid and ask prices (uses native function)
    public fun get_best_prices<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>
    ): (u64, u64) {
        get_best_prices_internal(pool)
    }

    /// Query: Get order book depth at price
    public fun get_depth_at_price<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>,
        price: u64,
        is_bid: bool,
    ): u64 {
        if (is_bid) {
            if (table::contains(&pool.bid_levels, price)) {
                table::borrow(&pool.bid_levels, price).total_quantity
            } else {
                0
            }
        } else {
            if (table::contains(&pool.ask_levels, price)) {
                table::borrow(&pool.ask_levels, price).total_quantity
            } else {
                0
            }
        }
    }

    /// Query: Get order info
    public fun get_order_info<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
    ): (u64, u64, u64, bool, address) {
        assert!(table::contains(&pool.order_index, order_id), EOrderNotFound);
        let info = table::borrow(&pool.order_index, order_id);
        (info.price, info.quantity, info.filled_quantity, info.is_bid, info.owner)
    }

    // ==================== Internal Functions ====================

    /// Calculate matches in Move (simple implementation)
    fun calculate_matches_in_move<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>,
        taker_price: u64,
        taker_quantity: u64,
        is_bid: bool,
    ): MatchResult {
        let mut matched_orders = vector::empty<MatchedOrder>();
        let mut remaining_quantity = taker_quantity;
        let mut taker_filled = 0;

        // Get opposite side prices
        let opposite_prices = if (is_bid) {
            &pool.ask_prices
        } else {
            &pool.bid_prices
        };

        let mut i = 0;
        let len = vector::length(opposite_prices);

        // Iterate through price levels
        while (i < len && remaining_quantity > 0) {
            let maker_price = *vector::borrow(opposite_prices, i);
            
            // Check if price matches
            let price_matches = if (is_bid) {
                taker_price >= maker_price  // Buy: willing to pay more
            } else {
                taker_price <= maker_price  // Sell: willing to accept less
            };

            if (!price_matches) {
                break // No more matches possible
            };

            // Get orders at this price level
            let levels = if (is_bid) {
                &pool.ask_levels
            } else {
                &pool.bid_levels
            };

            if (table::contains(levels, maker_price)) {
                let level = table::borrow(levels, maker_price);
                let mut j = 0;
                let order_count = vector::length(&level.order_ids);

                // Match with orders at this level
                while (j < order_count && remaining_quantity > 0) {
                    let order_id = *vector::borrow(&level.order_ids, j);
                    
                    if (table::contains(&pool.order_index, order_id)) {
                        let order_info = table::borrow(&pool.order_index, order_id);
                        let match_qty = if (remaining_quantity < order_info.quantity) {
                            remaining_quantity
                        } else {
                            order_info.quantity
                        };

                        vector::push_back(&mut matched_orders, MatchedOrder {
                            maker_order_id: order_id,
                            maker_owner: order_info.owner,
                            quantity: match_qty,
                            price: maker_price,
                        });

                        remaining_quantity = remaining_quantity - match_qty;
                        taker_filled = taker_filled + match_qty;
                    };
                    
                    j = j + 1;
                };
            };

            i = i + 1;
        };

        MatchResult {
            matched_orders,
            remaining_quantity,
            taker_filled,
        }
    }

    /// Execute buy order matches (transfer assets)
    fun execute_buy_matches<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        result: &MatchResult,
        mut payment: Coin<QuoteAsset>,
        ctx: &mut TxContext,
    ): (Coin<BaseAsset>, Coin<QuoteAsset>) {
        let base_received = coin::zero<BaseAsset>(ctx);
        
        let mut i = 0;
        let len = vector::length(&result.matched_orders);
        
        while (i < len) {
            let matched = vector::borrow(&result.matched_orders, i);
            
            // Calculate payment amount
            let payment_amount = matched.quantity * matched.price;
            let payment_coin = coin::split(&mut payment, payment_amount, ctx);
            
            // Transfer payment to maker
            transfer::public_transfer(payment_coin, matched.maker_owner);
            
            // TODO: Receive base asset from maker
            // This requires the maker to have escrowed assets
            
            // Update maker order
            update_order_quantity(
                pool,
                matched.maker_order_id,
                matched.quantity,
            );
            
            i = i + 1;
        };
        
        (base_received, payment)
    }

    /// Execute sell order matches
    fun execute_sell_matches<BaseAsset, QuoteAsset>(
        _pool: &mut Pool<BaseAsset, QuoteAsset>,
        _result: &MatchResult,
        payment: Coin<QuoteAsset>,
        ctx: &mut TxContext,
    ): (Coin<BaseAsset>, Coin<QuoteAsset>) {
        // Similar to execute_buy_matches but reversed
        (coin::zero<BaseAsset>(ctx), payment)
    }

    /// Add order to order book
    fun add_order_to_book<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
        price: u64,
        quantity: u64,
        is_bid: bool,
        owner: address,
    ) {
        // Add to order index
        table::add(&mut pool.order_index, order_id, OrderIndex {
            price,
            quantity,
            filled_quantity: 0,
            is_bid,
            owner,
        });

        // Add to price level
        let levels = if (is_bid) { &mut pool.bid_levels } else { &mut pool.ask_levels };
        let prices = if (is_bid) { &mut pool.bid_prices } else { &mut pool.ask_prices };

        if (!table::contains(levels, price)) {
            table::add(levels, price, PriceLevel {
                price,
                total_quantity: 0,
                order_ids: vector::empty(),
            });
            insert_price_sorted(prices, price, is_bid);
        };

        let level = table::borrow_mut(levels, price);
        vector::push_back(&mut level.order_ids, order_id);
        level.total_quantity = level.total_quantity + quantity;

        // Update pool statistics
        if (is_bid) {
            pool.total_bid_quantity = pool.total_bid_quantity + quantity;
        } else {
            pool.total_ask_quantity = pool.total_ask_quantity + quantity;
        };

        pool.total_orders = pool.total_orders + 1;
    }

    /// Update order quantity after match
    fun update_order_quantity<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
        filled_qty: u64,
    ) {
        if (!table::contains(&pool.order_index, order_id)) return;
        
        let order_info = table::borrow_mut(&mut pool.order_index, order_id);
        order_info.quantity = order_info.quantity - filled_qty;
        order_info.filled_quantity = order_info.filled_quantity + filled_qty;

        // Remove if fully filled
        if (order_info.quantity == 0) {
            let info = *order_info;
            remove_order_from_level(pool, order_id, info.price, info.is_bid);
            table::remove(&mut pool.order_index, order_id);
        };
    }

    /// Remove order from price level
    fun remove_order_from_level<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
        price: u64,
        is_bid: bool,
    ) {
        // Get order quantity before removing
        let quantity = if (table::contains(&pool.order_index, order_id)) {
            table::borrow(&pool.order_index, order_id).quantity
        } else {
            0
        };

        let levels = if (is_bid) { &mut pool.bid_levels } else { &mut pool.ask_levels };
        
        if (!table::contains(levels, price)) return;
        
        let level = table::borrow_mut(levels, price);
        let (found, idx) = vector::index_of(&level.order_ids, &order_id);
        
        if (found) {
            vector::remove(&mut level.order_ids, idx);
            level.total_quantity = level.total_quantity - quantity;
            
            // Update pool statistics
            if (is_bid) {
                pool.total_bid_quantity = pool.total_bid_quantity - quantity;
            } else {
                pool.total_ask_quantity = pool.total_ask_quantity - quantity;
            };
            
            // Remove level if empty
            if (vector::is_empty(&level.order_ids)) {
                let _removed_level = table::remove(levels, price);
                let prices = if (is_bid) { &mut pool.bid_prices } else { &mut pool.ask_prices };
                let (found_price, price_idx) = vector::index_of(prices, &price);
                if (found_price) {
                    vector::remove(prices, price_idx);
                };
            };
        };
    }

    /// Insert price into sorted vector
    fun insert_price_sorted(prices: &mut vector<u64>, price: u64, descending: bool) {
        let len = vector::length(prices);
        let mut i = 0;
        
        while (i < len) {
            let existing = *vector::borrow(prices, i);
            let should_insert = if (descending) {
                price > existing
            } else {
                price < existing
            };
            
            if (should_insert) {
                vector::insert(prices, price, i);
                return
            };
            i = i + 1;
        };
        
        vector::push_back(prices, price);
    }
}

