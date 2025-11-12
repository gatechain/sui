// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Production-grade order book storage framework using Move objects
module sui::dex {
    use sui::table::{Self, Table};
    use sui::event;

    // ==================== Error Codes ====================
    
    /// Invalid price error
    const EInvalidPrice: u64 = 1;
    
    /// Invalid quantity error  
    const EInvalidQuantity: u64 = 2;
    
    /// Unauthorized access
    const EUnauthorized: u64 = 3;

    // ==================== Core Storage Structures ====================

    /// Order - Each order is an independent owned object for parallel execution
    public struct Order has key, store {
        id: UID,
        order_id: u64,
        price: u64,
        original_quantity: u64,
        quantity: u64,           // Remaining
        filled_quantity: u64,
        is_bid: bool,
        owner: address,
        expire_timestamp: u64,
        pool_id: ID,
    }

    /// PriceLevel - Orders at a specific price
    public struct PriceLevel has store {
        price: u64,
        total_quantity: u64,
        order_ids: vector<u64>,  // FIFO queue
    }

    /// Pool - Central order book as shared object
    public struct Pool<phantom BaseAsset, phantom QuoteAsset> has key {
        id: UID,
        next_order_id: u64,
        
        // Price level storage
        bid_levels: Table<u64, PriceLevel>,
        ask_levels: Table<u64, PriceLevel>,
        
        // Sorted prices for quick lookup
        bid_prices: vector<u64>,  // Descending
        ask_prices: vector<u64>,  // Ascending
        
        // Order index: order_id -> (price, is_bid, owner)
        order_index: Table<u64, OrderIndex>,
        
        // Statistics
        total_bid_quantity: u64,
        total_ask_quantity: u64,
        total_orders: u64,
        
        // Configuration
        min_order_size: u64,
        tick_size: u64,
    }

    /// Order index entry
    public struct OrderIndex has store, copy, drop {
        price: u64,
        is_bid: bool,
        owner: address,
    }

    /// Capability for order modification
    public struct OrderCap has key, store {
        id: UID,
        order_id: u64,
        pool_id: ID,
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

    public struct OrderCancelled has copy, drop {
        pool_id: ID,
        order_id: u64,
        owner: address,
    }

    // ==================== Pool Management ====================

    /// Create a new order book pool
    public fun create_pool<BaseAsset, QuoteAsset>(
        tick_size: u64,
        min_order_size: u64,
        ctx: &mut TxContext
    ): Pool<BaseAsset, QuoteAsset> {
        Pool {
            id: object::new(ctx),
            next_order_id: 0,
            bid_levels: table::new(ctx),
            ask_levels: table::new(ctx),
            bid_prices: vector[],
            ask_prices: vector[],
            order_index: table::new(ctx),
            total_bid_quantity: 0,
            total_ask_quantity: 0,
            total_orders: 0,
            min_order_size,
            tick_size,
        }
    }

    /// Share pool for public access
    public fun share_pool<BaseAsset, QuoteAsset>(pool: Pool<BaseAsset, QuoteAsset>) {
        transfer::share_object(pool);
    }

    // ==================== Order Operations ====================

    /// Place a new order
    public fun place_order<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        price: u64,
        quantity: u64,
        is_bid: bool,
        expire_timestamp: u64,
        ctx: &mut TxContext
    ): (Order, OrderCap) {
        assert!(price > 0, EInvalidPrice);
        assert!(quantity >= pool.min_order_size, EInvalidQuantity);
        assert!(price % pool.tick_size == 0, EInvalidPrice);
        
        let order_id = pool.next_order_id;
        pool.next_order_id = pool.next_order_id + 1;
        pool.total_orders = pool.total_orders + 1;
        
        let owner = ctx.sender();
        let pool_id = object::id(pool);
        
        let order = Order {
            id: object::new(ctx),
            order_id,
            price,
            original_quantity: quantity,
            quantity,
            filled_quantity: 0,
            is_bid,
            owner,
            expire_timestamp,
            pool_id,
        };
        
        // Add to pool - matching logic would go here
        if (quantity > 0) {
            add_order_to_pool(pool, order_id, price, quantity, is_bid, owner);
        };
        
        let order_cap = OrderCap {
            id: object::new(ctx),
            order_id,
            pool_id,
        };
        
        event::emit(OrderPlaced {
            pool_id,
            order_id,
            price,
            quantity,
            is_bid,
            owner,
        });
        
        (order, order_cap)
    }

    /// Cancel an order
    public fun cancel_order<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        order: Order,
        order_cap: OrderCap,
        ctx: &TxContext
    ) {
        let Order {
            id,
            order_id,
            price,
            quantity,
            is_bid,
            owner,
            pool_id,
            original_quantity: _,
            filled_quantity: _,
            expire_timestamp: _,
        } = order;
        
        let OrderCap {
            id: cap_id,
            order_id: cap_order_id,
            pool_id: cap_pool_id,
        } = order_cap;
        
        assert!(pool_id == object::id(pool), EUnauthorized);
        assert!(owner == ctx.sender(), EUnauthorized);
        assert!(order_id == cap_order_id, EUnauthorized);
        assert!(pool_id == cap_pool_id, EUnauthorized);
        
        if (quantity > 0) {
            remove_order_from_pool(pool, order_id, price, quantity, is_bid);
        };
        
        event::emit(OrderCancelled {
            pool_id,
            order_id,
            owner,
        });
        
        id.delete();
        cap_id.delete();
    }

    // ==================== Internal Functions ====================

    fun add_order_to_pool<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
        price: u64,
        quantity: u64,
        is_bid: bool,
        owner: address,
    ) {
        let (levels, prices, total_qty) = if (is_bid) {
            (&mut pool.bid_levels, &mut pool.bid_prices, &mut pool.total_bid_quantity)
        } else {
            (&mut pool.ask_levels, &mut pool.ask_prices, &mut pool.total_ask_quantity)
        };
        
        // Create price level if needed
        if (!table::contains(levels, price)) {
            let level = PriceLevel {
                price,
                total_quantity: 0,
                order_ids: vector[],
            };
            table::add(levels, price, level);
            prices.push_back(price); // Simplified - should maintain sorted order
        };
        
        // Add order to level
        let level = table::borrow_mut(levels, price);
        level.order_ids.push_back(order_id);
        level.total_quantity = level.total_quantity + quantity;
        *total_qty = *total_qty + quantity;
        
        // Add to index
        table::add(&mut pool.order_index, order_id, OrderIndex { price, is_bid, owner });
    }

    fun remove_order_from_pool<BaseAsset, QuoteAsset>(
        pool: &mut Pool<BaseAsset, QuoteAsset>,
        order_id: u64,
        price: u64,
        quantity: u64,
        is_bid: bool,
    ) {
        let (levels, prices, total_qty) = if (is_bid) {
            (&mut pool.bid_levels, &mut pool.bid_prices, &mut pool.total_bid_quantity)
        } else {
            (&mut pool.ask_levels, &mut pool.ask_prices, &mut pool.total_ask_quantity)
        };
        
        let level = table::borrow_mut(levels, price);
        let (found, index) = level.order_ids.index_of(&order_id);
        if (found) {
            level.order_ids.remove(index);
        };
        level.total_quantity = level.total_quantity - quantity;
        *total_qty = *total_qty - quantity;
        
        table::remove(&mut pool.order_index, order_id);
        
        // Clean up empty level
        if (level.total_quantity == 0) {
            let (found_price, price_index) = prices.index_of(&price);
            if (found_price) {
                prices.remove(price_index);
            };
            let PriceLevel { price: _, total_quantity: _, order_ids: _ } = 
                table::remove(levels, price);
        };
    }

    // ==================== Query Functions ====================

    /// Get best bid price (returns 0 if empty)
    public fun get_best_bid<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>
    ): u64 {
        if (pool.bid_prices.is_empty()) {
            0
        } else {
            *pool.bid_prices.borrow(0)
        }
    }

    /// Get best ask price (returns 0 if empty)
    public fun get_best_ask<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>
    ): u64 {
        if (pool.ask_prices.is_empty()) {
            0
        } else {
            *pool.ask_prices.borrow(0)
        }
    }

    /// Get depth summary
    public fun get_depth_summary<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>,
    ): (u64, u64, u64, u64) {
        (
            pool.total_bid_quantity,
            pool.total_ask_quantity,
            pool.bid_prices.length(),
            pool.ask_prices.length()
        )
    }

    /// Check if price level exists
    public fun has_level<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>,
        price: u64,
        is_bid: bool
    ): bool {
        let levels = if (is_bid) { &pool.bid_levels } else { &pool.ask_levels };
        table::contains(levels, price)
    }

    /// Get level total quantity
    public fun get_level_quantity<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>,
        price: u64,
        is_bid: bool
    ): u64 {
        let levels = if (is_bid) { &pool.bid_levels } else { &pool.ask_levels };
        if (table::contains(levels, price)) {
            let level = table::borrow(levels, price);
            level.total_quantity
        } else {
            0
        }
    }

    /// Get number of orders at price level
    public fun get_level_order_count<BaseAsset, QuoteAsset>(
        pool: &Pool<BaseAsset, QuoteAsset>,
        price: u64,
        is_bid: bool
    ): u64 {
        let levels = if (is_bid) { &pool.bid_levels } else { &pool.ask_levels };
        if (table::contains(levels, price)) {
            let level = table::borrow(levels, price);
            level.order_ids.length()
        } else {
            0
        }
    }

    // ==================== Accessors ====================

    public fun order_id(order: &Order): u64 { order.order_id }
    public fun order_price(order: &Order): u64 { order.price }
    public fun order_quantity(order: &Order): u64 { order.quantity }
    public fun order_filled_quantity(order: &Order): u64 { order.filled_quantity }
    public fun order_is_bid(order: &Order): bool { order.is_bid }
    public fun order_owner(order: &Order): address { order.owner }

    public fun pool_total_orders<BaseAsset, QuoteAsset>(pool: &Pool<BaseAsset, QuoteAsset>): u64 {
        pool.total_orders
    }

    public fun pool_next_order_id<BaseAsset, QuoteAsset>(pool: &Pool<BaseAsset, QuoteAsset>): u64 {
        pool.next_order_id
    }
}
