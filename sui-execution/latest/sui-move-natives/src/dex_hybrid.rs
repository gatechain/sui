// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

//! Hybrid DEX implementation: Native matching engine + Move object storage
//! 
//! Architecture:
//! - Native: High-performance matching algorithm (stateless)
//! - Move: Data persistence, asset transfers, query interface

use move_binary_format::errors::{PartialVMError, PartialVMResult};
use move_core_types::{account_address::AccountAddress, vm_status::StatusCode};
use move_vm_runtime::native_functions::NativeContext;
use move_vm_types::{
    loaded_data::runtime_types::Type,
    natives::function::NativeResult,
    values::{Struct, Value, StructRef, Vector, VectorSpecialization},
    pop_arg,
};
use smallvec::smallvec;
use std::collections::VecDeque;

/// Order information passed from Move
#[derive(Debug, Clone)]
pub struct Order {
    pub order_id: u64,
    pub price: u64,
    pub quantity: u64,
    pub owner: AccountAddress,
}

/// Match result to return to Move
#[derive(Debug)]
pub struct MatchResult {
    pub matched_orders: Vec<MatchedOrder>,
    pub remaining_quantity: u64,
    pub taker_filled: u64,
}

/// Single matched order
#[derive(Debug)]
pub struct MatchedOrder {
    pub maker_order_id: u64,
    pub maker_owner: AccountAddress,
    pub quantity: u64,
    pub price: u64,
}

/// Native function: Calculate order matches
/// 
/// Parameters from Move:
/// - taker_price: u64
/// - taker_quantity: u64
/// - taker_owner: address
/// - is_bid: bool
/// - opposite_orders: vector<Order> (from Pool's bid_levels or ask_levels)
/// 
/// Returns to Move:
/// - matched_orders: vector<MatchedOrder>
/// - remaining_quantity: u64
/// - taker_filled: u64
pub fn calculate_matches_native(
    context: &mut NativeContext,
    _ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(args.len() == 5);

    // Pop arguments in reverse order
    let _opposite_orders_value = pop_arg!(args, Value);
    let is_bid = pop_arg!(args, bool);
    let _taker_owner = pop_arg!(args, AccountAddress);
    let taker_quantity = pop_arg!(args, u64);
    let taker_price = pop_arg!(args, u64);

    // Validate inputs
    if taker_price == 0 {
        return Err(PartialVMError::new(StatusCode::ABORTED)
            .with_message("Price must be greater than 0".to_string()));
    }
    if taker_quantity == 0 {
        return Err(PartialVMError::new(StatusCode::ABORTED)
            .with_message("Quantity must be greater than 0".to_string()));
    }

    // NOTE: Matching is now done in Move layer, so we don't parse orders here
    // This keeps the native function signature compatible but delegates logic to Move
    let opposite_orders: Vec<Order> = Vec::new();

    // Execute matching algorithm
    let result = calculate_matches(
        taker_price,
        taker_quantity,
        is_bid,
        &opposite_orders,
    );

    // Convert result to Move values
    let result_value = create_match_result_struct(result)?;

    let cost = context.gas_used();
    Ok(NativeResult::ok(cost, smallvec![result_value]))
}

/// Core matching algorithm (stateless, pure computation)
/// NOTE: This is currently not used as matching is done in Move layer
/// Kept for potential future optimization
fn calculate_matches(
    taker_price: u64,
    taker_quantity: u64,
    is_bid: bool,
    opposite_orders: &[Order],
) -> MatchResult {
    let mut remaining = taker_quantity;
    let mut matched = Vec::new();
    let mut total_filled = 0;

    for maker_order in opposite_orders {
        if remaining == 0 {
            break;
        }

        // Check if price matches
        let price_matches = if is_bid {
            // Buy order: willing to pay taker_price, matches if maker's ask <= taker_price
            taker_price >= maker_order.price
        } else {
            // Sell order: willing to accept taker_price, matches if maker's bid >= taker_price
            taker_price <= maker_order.price
        };

        if !price_matches {
            break; // Orders are sorted, no more matches possible
        }

        // Calculate match quantity
        let match_qty = remaining.min(maker_order.quantity);

        matched.push(MatchedOrder {
            maker_order_id: maker_order.order_id,
            maker_owner: maker_order.owner,
            quantity: match_qty,
            price: maker_order.price, // Use maker's price (price-time priority)
        });

        remaining -= match_qty;
        total_filled += match_qty;
    }

    MatchResult {
        matched_orders: matched,
        remaining_quantity: remaining,
        taker_filled: total_filled,
    }
}


/// Create MatchResult struct to return to Move
/// ```move
/// struct MatchResult {
///     matched_orders: vector<MatchedOrder>,
///     remaining_quantity: u64,
///     taker_filled: u64,
/// }
/// struct MatchedOrder {
///     maker_order_id: u64,
///     maker_owner: address,
///     quantity: u64,
///     price: u64,
/// }
/// ```
fn create_match_result_struct(result: MatchResult) -> PartialVMResult<Value> {
    // Create vector of MatchedOrder structs
    let matched_order_values: Vec<Value> = result.matched_orders
        .into_iter()
        .map(|order| {
            let fields = vec![
                Value::u64(order.maker_order_id),
                Value::address(order.maker_owner),
                Value::u64(order.quantity),
                Value::u64(order.price),
            ];
            Value::struct_(Struct::pack(fields))
        })
        .collect();

    // Create vector using Vector::pack with Container specialization
    let matched_orders_vector = Vector::pack(
        VectorSpecialization::Container,
        matched_order_values.into_iter()
    )?;

    // Create MatchResult struct
    let result_fields = vec![
        matched_orders_vector.into(),  // Convert Vector to Value
        Value::u64(result.remaining_quantity),
        Value::u64(result.taker_filled),
    ];

    Ok(Value::struct_(Struct::pack(result_fields)))
}

/// Native function: Update order in Pool
/// This is called by Move after asset transfers to update the order book state
/// 
/// Parameters:
/// - pool: &mut Pool
/// - order_id: u64
/// - new_quantity: u64
/// - filled_quantity: u64
pub fn update_order_native(
    context: &mut NativeContext,
    _ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(args.len() == 4);

    let _filled_quantity = pop_arg!(args, u64);
    let _new_quantity = pop_arg!(args, u64);
    let _order_id = pop_arg!(args, u64);
    let _pool_ref = pop_arg!(args, StructRef);

    // In a full implementation, this would:
    // 1. Access Pool's order_index Table
    // 2. Update the order's quantity
    // 3. Update price level statistics
    // 4. Remove order if fully filled
    //
    // For now, we delegate to Move code for actual Table updates
    // Native function can be used for batch updates or complex operations

    let cost = context.gas_used();
    Ok(NativeResult::ok(cost, smallvec![Value::bool(true)]))
}

/// Native function: Get best prices from order book
/// Returns (best_bid, best_ask)
pub fn get_best_prices_native(
    context: &mut NativeContext,
    _ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(args.len() == 1);

    let _pool_ref = pop_arg!(args, StructRef);
    
    // For simplicity, return 0 for both prices
    // In a full implementation, this would parse the Pool struct and extract prices
    let best_bid = 0u64;
    let best_ask = 0u64;

    let cost = context.gas_used();
    Ok(NativeResult::ok(
        cost,
        smallvec![Value::u64(best_bid), Value::u64(best_ask)],
    ))
}

