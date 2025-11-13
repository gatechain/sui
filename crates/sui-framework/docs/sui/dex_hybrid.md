---
title: Module `sui::dex_hybrid`
---

Hybrid DEX: Native matching engine + Move object storage

Architecture:
- Move: Data persistence (Pool object with Table storage)
- Native: High-performance matching algorithm
- Move: Asset transfers using Coin module


-  [Struct `Pool`](#sui_dex_hybrid_Pool)
-  [Struct `PriceLevel`](#sui_dex_hybrid_PriceLevel)
-  [Struct `OrderIndex`](#sui_dex_hybrid_OrderIndex)
-  [Struct `Order`](#sui_dex_hybrid_Order)
-  [Struct `MatchResult`](#sui_dex_hybrid_MatchResult)
-  [Struct `MatchedOrder`](#sui_dex_hybrid_MatchedOrder)
-  [Struct `OrderPlaced`](#sui_dex_hybrid_OrderPlaced)
-  [Struct `OrderMatched`](#sui_dex_hybrid_OrderMatched)
-  [Struct `OrderFilled`](#sui_dex_hybrid_OrderFilled)
-  [Constants](#@Constants_0)
-  [Function `get_best_prices_internal`](#sui_dex_hybrid_get_best_prices_internal)
-  [Function `create_pool`](#sui_dex_hybrid_create_pool)
-  [Function `place_limit_order`](#sui_dex_hybrid_place_limit_order)
-  [Function `cancel_order`](#sui_dex_hybrid_cancel_order)
-  [Function `get_best_prices`](#sui_dex_hybrid_get_best_prices)
-  [Function `get_depth_at_price`](#sui_dex_hybrid_get_depth_at_price)
-  [Function `get_order_info`](#sui_dex_hybrid_get_order_info)
-  [Function `calculate_matches_in_move`](#sui_dex_hybrid_calculate_matches_in_move)
-  [Function `execute_buy_matches`](#sui_dex_hybrid_execute_buy_matches)
-  [Function `execute_sell_matches`](#sui_dex_hybrid_execute_sell_matches)
-  [Function `add_order_to_book`](#sui_dex_hybrid_add_order_to_book)
-  [Function `update_order_quantity`](#sui_dex_hybrid_update_order_quantity)
-  [Function `remove_order_from_level`](#sui_dex_hybrid_remove_order_from_level)
-  [Function `insert_price_sorted`](#sui_dex_hybrid_insert_price_sorted)


<pre><code><b>use</b> <a href="../std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../sui/accumulator.md#sui_accumulator">sui::accumulator</a>;
<b>use</b> <a href="../sui/accumulator_metadata.md#sui_accumulator_metadata">sui::accumulator_metadata</a>;
<b>use</b> <a href="../sui/accumulator_settlement.md#sui_accumulator_settlement">sui::accumulator_settlement</a>;
<b>use</b> <a href="../sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../sui/bcs.md#sui_bcs">sui::bcs</a>;
<b>use</b> <a href="../sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../sui/funds_accumulator.md#sui_funds_accumulator">sui::funds_accumulator</a>;
<b>use</b> <a href="../sui/hash.md#sui_hash">sui::hash</a>;
<b>use</b> <a href="../sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="sui_dex_hybrid_Pool"></a>

## Struct `Pool`

Pool - Order book as shared object (on-chain queryable)


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;<b>phantom</b> BaseAsset, <b>phantom</b> QuoteAsset&gt; <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>next_order_id: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>bid_levels: <a href="../sui/table.md#sui_table_Table">sui::table::Table</a>&lt;u64, <a href="../sui/dex_hybrid.md#sui_dex_hybrid_PriceLevel">sui::dex_hybrid::PriceLevel</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>ask_levels: <a href="../sui/table.md#sui_table_Table">sui::table::Table</a>&lt;u64, <a href="../sui/dex_hybrid.md#sui_dex_hybrid_PriceLevel">sui::dex_hybrid::PriceLevel</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>bid_prices: vector&lt;u64&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>ask_prices: vector&lt;u64&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>order_index: <a href="../sui/table.md#sui_table_Table">sui::table::Table</a>&lt;u64, <a href="../sui/dex_hybrid.md#sui_dex_hybrid_OrderIndex">sui::dex_hybrid::OrderIndex</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>total_bid_quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>total_ask_quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>total_orders: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>total_volume: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>min_order_size: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>tick_size: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_hybrid_PriceLevel"></a>

## Struct `PriceLevel`

Price level containing orders at specific price


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_PriceLevel">PriceLevel</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>price: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>total_quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>order_ids: vector&lt;u64&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_hybrid_OrderIndex"></a>

## Struct `OrderIndex`

Order index entry


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_OrderIndex">OrderIndex</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>price: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>filled_quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>is_bid: bool</code>
</dt>
<dd>
</dd>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_hybrid_Order"></a>

## Struct `Order`

Order struct for native function


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Order">Order</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>order_id: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>price: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_hybrid_MatchResult"></a>

## Struct `MatchResult`

Match result from native function


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchResult">MatchResult</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>matched_orders: vector&lt;<a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchedOrder">sui::dex_hybrid::MatchedOrder</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>remaining_quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>taker_filled: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_hybrid_MatchedOrder"></a>

## Struct `MatchedOrder`

Single matched order


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchedOrder">MatchedOrder</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>maker_order_id: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>maker_owner: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>price: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_hybrid_OrderPlaced"></a>

## Struct `OrderPlaced`



<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_OrderPlaced">OrderPlaced</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_id: <a href="../sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>order_id: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>price: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>is_bid: bool</code>
</dt>
<dd>
</dd>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_hybrid_OrderMatched"></a>

## Struct `OrderMatched`



<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_OrderMatched">OrderMatched</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_id: <a href="../sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>taker_order_id: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>maker_order_id: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>price: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>quantity: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>taker: <b>address</b></code>
</dt>
<dd>
</dd>
<dt>
<code>maker: <b>address</b></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_hybrid_OrderFilled"></a>

## Struct `OrderFilled`



<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_OrderFilled">OrderFilled</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_id: <a href="../sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>order_id: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>total_filled: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="sui_dex_hybrid_EInvalidPrice"></a>



<pre><code><b>const</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_EInvalidPrice">EInvalidPrice</a>: u64 = 1;
</code></pre>



<a name="sui_dex_hybrid_EInvalidQuantity"></a>



<pre><code><b>const</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_EInvalidQuantity">EInvalidQuantity</a>: u64 = 2;
</code></pre>



<a name="sui_dex_hybrid_EUnauthorized"></a>



<pre><code><b>const</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_EUnauthorized">EUnauthorized</a>: u64 = 3;
</code></pre>



<a name="sui_dex_hybrid_EOrderNotFound"></a>



<pre><code><b>const</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_EOrderNotFound">EOrderNotFound</a>: u64 = 4;
</code></pre>



<a name="sui_dex_hybrid_get_best_prices_internal"></a>

## Function `get_best_prices_internal`

Native function: Get best bid and ask prices


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_get_best_prices_internal">get_best_prices_internal</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>native</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_get_best_prices_internal">get_best_prices_internal</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;
): (u64, u64);
</code></pre>



</details>

<a name="sui_dex_hybrid_create_pool"></a>

## Function `create_pool`

Create a new trading pool


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_create_pool">create_pool</a>&lt;BaseAsset, QuoteAsset&gt;(min_order_size: u64, tick_size: u64, ctx: &<b>mut</b> <a href="../sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_create_pool">create_pool</a>&lt;BaseAsset, QuoteAsset&gt;(
    min_order_size: u64,
    tick_size: u64,
    ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> pool = <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt; {
        id: <a href="../sui/object.md#sui_object_new">object::new</a>(ctx),
        next_order_id: 1,
        bid_levels: <a href="../sui/table.md#sui_table_new">table::new</a>(ctx),
        ask_levels: <a href="../sui/table.md#sui_table_new">table::new</a>(ctx),
        bid_prices: vector::empty(),
        ask_prices: vector::empty(),
        order_index: <a href="../sui/table.md#sui_table_new">table::new</a>(ctx),
        total_bid_quantity: 0,
        total_ask_quantity: 0,
        total_orders: 0,
        total_volume: 0,
        min_order_size,
        tick_size,
    };
    <a href="../sui/transfer.md#sui_transfer_share_object">transfer::share_object</a>(pool);
}
</code></pre>



</details>

<a name="sui_dex_hybrid_place_limit_order"></a>

## Function `place_limit_order`

Place a limit order
- Uses native function for high-performance matching
- Handles asset transfers in Move
- Updates on-chain state


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_place_limit_order">place_limit_order</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, price: u64, quantity: u64, is_bid: bool, payment: <a href="../sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;QuoteAsset&gt;, ctx: &<b>mut</b> <a href="../sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;BaseAsset&gt;, <a href="../sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;QuoteAsset&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_place_limit_order">place_limit_order</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    price: u64,
    quantity: u64,
    is_bid: bool,
    payment: Coin&lt;QuoteAsset&gt;,  // For buy orders
    ctx: &<b>mut</b> TxContext,
): (Coin&lt;BaseAsset&gt;, Coin&lt;QuoteAsset&gt;) {
    // Validate inputs
    <b>assert</b>!(price &gt; 0, <a href="../sui/dex_hybrid.md#sui_dex_hybrid_EInvalidPrice">EInvalidPrice</a>);
    <b>assert</b>!(quantity &gt;= pool.min_order_size, <a href="../sui/dex_hybrid.md#sui_dex_hybrid_EInvalidQuantity">EInvalidQuantity</a>);
    <b>let</b> taker_owner = <a href="../sui/tx_context.md#sui_tx_context_sender">tx_context::sender</a>(ctx);
    <b>let</b> order_id = pool.next_order_id;
    pool.next_order_id = pool.next_order_id + 1;
    // Perform matching in Move (simpler than <b>native</b> <b>for</b> now)
    <b>let</b> match_result = <a href="../sui/dex_hybrid.md#sui_dex_hybrid_calculate_matches_in_move">calculate_matches_in_move</a>(
        pool,
        price,
        quantity,
        is_bid,
    );
    // Process matched orders (asset transfers)
    <b>let</b> (base_received, quote_change) = <b>if</b> (is_bid) {
        <a href="../sui/dex_hybrid.md#sui_dex_hybrid_execute_buy_matches">execute_buy_matches</a>(pool, &match_result, payment, ctx)
    } <b>else</b> {
        // For sell orders, payment should be empty, but we still need to consume it
        <a href="../sui/dex_hybrid.md#sui_dex_hybrid_execute_sell_matches">execute_sell_matches</a>(pool, &match_result, payment, ctx)
    };
    // Update order book with remaining quantity
    <b>if</b> (match_result.remaining_quantity &gt; 0) {
        <a href="../sui/dex_hybrid.md#sui_dex_hybrid_add_order_to_book">add_order_to_book</a>(
            pool,
            order_id,
            price,
            match_result.remaining_quantity,
            is_bid,
            taker_owner,
        );
    };
    // Emit events
    <a href="../sui/event.md#sui_event_emit">event::emit</a>(<a href="../sui/dex_hybrid.md#sui_dex_hybrid_OrderPlaced">OrderPlaced</a> {
        pool_id: <a href="../sui/object.md#sui_object_id">object::id</a>(pool),
        order_id,
        price,
        quantity,
        is_bid,
        owner: taker_owner,
    });
    <b>if</b> (match_result.taker_filled &gt; 0) {
        <a href="../sui/event.md#sui_event_emit">event::emit</a>(<a href="../sui/dex_hybrid.md#sui_dex_hybrid_OrderFilled">OrderFilled</a> {
            pool_id: <a href="../sui/object.md#sui_object_id">object::id</a>(pool),
            order_id,
            total_filled: match_result.taker_filled,
            owner: taker_owner,
        });
    };
    // Update statistics
    pool.total_volume = pool.total_volume + match_result.taker_filled;
    (base_received, quote_change)
}
</code></pre>



</details>

<a name="sui_dex_hybrid_cancel_order"></a>

## Function `cancel_order`

Cancel an order


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_cancel_order">cancel_order</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, order_id: u64, ctx: &<a href="../sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_cancel_order">cancel_order</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    order_id: u64,
    ctx: &TxContext,
) {
    <b>assert</b>!(<a href="../sui/table.md#sui_table_contains">table::contains</a>(&pool.order_index, order_id), <a href="../sui/dex_hybrid.md#sui_dex_hybrid_EOrderNotFound">EOrderNotFound</a>);
    <b>let</b> order_info = <a href="../sui/table.md#sui_table_borrow">table::borrow</a>(&pool.order_index, order_id);
    <b>let</b> caller = <a href="../sui/tx_context.md#sui_tx_context_sender">tx_context::sender</a>(ctx);
    <b>assert</b>!(order_info.owner == caller, <a href="../sui/dex_hybrid.md#sui_dex_hybrid_EUnauthorized">EUnauthorized</a>);
    // Remove from price level
    <a href="../sui/dex_hybrid.md#sui_dex_hybrid_remove_order_from_level">remove_order_from_level</a>(pool, order_id, order_info.price, order_info.is_bid);
    // Remove from index
    <a href="../sui/table.md#sui_table_remove">table::remove</a>(&<b>mut</b> pool.order_index, order_id);
    pool.total_orders = pool.total_orders - 1;
}
</code></pre>



</details>

<a name="sui_dex_hybrid_get_best_prices"></a>

## Function `get_best_prices`

Query: Get best bid and ask prices (uses native function)


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_get_best_prices">get_best_prices</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_get_best_prices">get_best_prices</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;
): (u64, u64) {
    <a href="../sui/dex_hybrid.md#sui_dex_hybrid_get_best_prices_internal">get_best_prices_internal</a>(pool)
}
</code></pre>



</details>

<a name="sui_dex_hybrid_get_depth_at_price"></a>

## Function `get_depth_at_price`

Query: Get order book depth at price


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_get_depth_at_price">get_depth_at_price</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, price: u64, is_bid: bool): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_get_depth_at_price">get_depth_at_price</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    price: u64,
    is_bid: bool,
): u64 {
    <b>if</b> (is_bid) {
        <b>if</b> (<a href="../sui/table.md#sui_table_contains">table::contains</a>(&pool.bid_levels, price)) {
            <a href="../sui/table.md#sui_table_borrow">table::borrow</a>(&pool.bid_levels, price).total_quantity
        } <b>else</b> {
            0
        }
    } <b>else</b> {
        <b>if</b> (<a href="../sui/table.md#sui_table_contains">table::contains</a>(&pool.ask_levels, price)) {
            <a href="../sui/table.md#sui_table_borrow">table::borrow</a>(&pool.ask_levels, price).total_quantity
        } <b>else</b> {
            0
        }
    }
}
</code></pre>



</details>

<a name="sui_dex_hybrid_get_order_info"></a>

## Function `get_order_info`

Query: Get order info


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_get_order_info">get_order_info</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, order_id: u64): (u64, u64, u64, bool, <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_get_order_info">get_order_info</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    order_id: u64,
): (u64, u64, u64, bool, <b>address</b>) {
    <b>assert</b>!(<a href="../sui/table.md#sui_table_contains">table::contains</a>(&pool.order_index, order_id), <a href="../sui/dex_hybrid.md#sui_dex_hybrid_EOrderNotFound">EOrderNotFound</a>);
    <b>let</b> info = <a href="../sui/table.md#sui_table_borrow">table::borrow</a>(&pool.order_index, order_id);
    (info.price, info.quantity, info.filled_quantity, info.is_bid, info.owner)
}
</code></pre>



</details>

<a name="sui_dex_hybrid_calculate_matches_in_move"></a>

## Function `calculate_matches_in_move`

Calculate matches in Move (simple implementation)


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_calculate_matches_in_move">calculate_matches_in_move</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, taker_price: u64, taker_quantity: u64, is_bid: bool): <a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchResult">sui::dex_hybrid::MatchResult</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_calculate_matches_in_move">calculate_matches_in_move</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    taker_price: u64,
    taker_quantity: u64,
    is_bid: bool,
): <a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchResult">MatchResult</a> {
    <b>let</b> <b>mut</b> matched_orders = vector::empty&lt;<a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchedOrder">MatchedOrder</a>&gt;();
    <b>let</b> <b>mut</b> remaining_quantity = taker_quantity;
    <b>let</b> <b>mut</b> taker_filled = 0;
    // Get opposite side prices
    <b>let</b> opposite_prices = <b>if</b> (is_bid) {
        &pool.ask_prices
    } <b>else</b> {
        &pool.bid_prices
    };
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> len = vector::length(opposite_prices);
    // Iterate through price levels
    <b>while</b> (i &lt; len && remaining_quantity &gt; 0) {
        <b>let</b> maker_price = *vector::borrow(opposite_prices, i);
        // Check <b>if</b> price matches
        <b>let</b> price_matches = <b>if</b> (is_bid) {
            taker_price &gt;= maker_price  // Buy: willing to <a href="../sui/pay.md#sui_pay">pay</a> more
        } <b>else</b> {
            taker_price &lt;= maker_price  // Sell: willing to accept less
        };
        <b>if</b> (!price_matches) {
            <b>break</b> // No more matches possible
        };
        // Get orders at this price level
        <b>let</b> levels = <b>if</b> (is_bid) {
            &pool.ask_levels
        } <b>else</b> {
            &pool.bid_levels
        };
        <b>if</b> (<a href="../sui/table.md#sui_table_contains">table::contains</a>(levels, maker_price)) {
            <b>let</b> level = <a href="../sui/table.md#sui_table_borrow">table::borrow</a>(levels, maker_price);
            <b>let</b> <b>mut</b> j = 0;
            <b>let</b> order_count = vector::length(&level.order_ids);
            // Match with orders at this level
            <b>while</b> (j &lt; order_count && remaining_quantity &gt; 0) {
                <b>let</b> order_id = *vector::borrow(&level.order_ids, j);
                <b>if</b> (<a href="../sui/table.md#sui_table_contains">table::contains</a>(&pool.order_index, order_id)) {
                    <b>let</b> order_info = <a href="../sui/table.md#sui_table_borrow">table::borrow</a>(&pool.order_index, order_id);
                    <b>let</b> match_qty = <b>if</b> (remaining_quantity &lt; order_info.quantity) {
                        remaining_quantity
                    } <b>else</b> {
                        order_info.quantity
                    };
                    vector::push_back(&<b>mut</b> matched_orders, <a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchedOrder">MatchedOrder</a> {
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
    <a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchResult">MatchResult</a> {
        matched_orders,
        remaining_quantity,
        taker_filled,
    }
}
</code></pre>



</details>

<a name="sui_dex_hybrid_execute_buy_matches"></a>

## Function `execute_buy_matches`

Execute buy order matches (transfer assets)


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_execute_buy_matches">execute_buy_matches</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, result: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchResult">sui::dex_hybrid::MatchResult</a>, payment: <a href="../sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;QuoteAsset&gt;, ctx: &<b>mut</b> <a href="../sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;BaseAsset&gt;, <a href="../sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;QuoteAsset&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_execute_buy_matches">execute_buy_matches</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    result: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchResult">MatchResult</a>,
    <b>mut</b> payment: Coin&lt;QuoteAsset&gt;,
    ctx: &<b>mut</b> TxContext,
): (Coin&lt;BaseAsset&gt;, Coin&lt;QuoteAsset&gt;) {
    <b>let</b> base_received = <a href="../sui/coin.md#sui_coin_zero">coin::zero</a>&lt;BaseAsset&gt;(ctx);
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> len = vector::length(&result.matched_orders);
    <b>while</b> (i &lt; len) {
        <b>let</b> matched = vector::borrow(&result.matched_orders, i);
        // Calculate payment amount
        <b>let</b> payment_amount = matched.quantity * matched.price;
        <b>let</b> payment_coin = <a href="../sui/coin.md#sui_coin_split">coin::split</a>(&<b>mut</b> payment, payment_amount, ctx);
        // Transfer payment to maker
        <a href="../sui/transfer.md#sui_transfer_public_transfer">transfer::public_transfer</a>(payment_coin, matched.maker_owner);
        // TODO: Receive base asset from maker
        // This requires the maker to have escrowed assets
        // Update maker order
        <a href="../sui/dex_hybrid.md#sui_dex_hybrid_update_order_quantity">update_order_quantity</a>(
            pool,
            matched.maker_order_id,
            matched.quantity,
        );
        i = i + 1;
    };
    (base_received, payment)
}
</code></pre>



</details>

<a name="sui_dex_hybrid_execute_sell_matches"></a>

## Function `execute_sell_matches`

Execute sell order matches


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_execute_sell_matches">execute_sell_matches</a>&lt;BaseAsset, QuoteAsset&gt;(_pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, _result: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchResult">sui::dex_hybrid::MatchResult</a>, payment: <a href="../sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;QuoteAsset&gt;, ctx: &<b>mut</b> <a href="../sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;BaseAsset&gt;, <a href="../sui/coin.md#sui_coin_Coin">sui::coin::Coin</a>&lt;QuoteAsset&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_execute_sell_matches">execute_sell_matches</a>&lt;BaseAsset, QuoteAsset&gt;(
    _pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    _result: &<a href="../sui/dex_hybrid.md#sui_dex_hybrid_MatchResult">MatchResult</a>,
    payment: Coin&lt;QuoteAsset&gt;,
    ctx: &<b>mut</b> TxContext,
): (Coin&lt;BaseAsset&gt;, Coin&lt;QuoteAsset&gt;) {
    // Similar to <a href="../sui/dex_hybrid.md#sui_dex_hybrid_execute_buy_matches">execute_buy_matches</a> but reversed
    (<a href="../sui/coin.md#sui_coin_zero">coin::zero</a>&lt;BaseAsset&gt;(ctx), payment)
}
</code></pre>



</details>

<a name="sui_dex_hybrid_add_order_to_book"></a>

## Function `add_order_to_book`

Add order to order book


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_add_order_to_book">add_order_to_book</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, order_id: u64, price: u64, quantity: u64, is_bid: bool, owner: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_add_order_to_book">add_order_to_book</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    order_id: u64,
    price: u64,
    quantity: u64,
    is_bid: bool,
    owner: <b>address</b>,
) {
    // Add to order index
    <a href="../sui/table.md#sui_table_add">table::add</a>(&<b>mut</b> pool.order_index, order_id, <a href="../sui/dex_hybrid.md#sui_dex_hybrid_OrderIndex">OrderIndex</a> {
        price,
        quantity,
        filled_quantity: 0,
        is_bid,
        owner,
    });
    // Add to price level
    <b>let</b> levels = <b>if</b> (is_bid) { &<b>mut</b> pool.bid_levels } <b>else</b> { &<b>mut</b> pool.ask_levels };
    <b>let</b> prices = <b>if</b> (is_bid) { &<b>mut</b> pool.bid_prices } <b>else</b> { &<b>mut</b> pool.ask_prices };
    <b>if</b> (!<a href="../sui/table.md#sui_table_contains">table::contains</a>(levels, price)) {
        <a href="../sui/table.md#sui_table_add">table::add</a>(levels, price, <a href="../sui/dex_hybrid.md#sui_dex_hybrid_PriceLevel">PriceLevel</a> {
            price,
            total_quantity: 0,
            order_ids: vector::empty(),
        });
        <a href="../sui/dex_hybrid.md#sui_dex_hybrid_insert_price_sorted">insert_price_sorted</a>(prices, price, is_bid);
    };
    <b>let</b> level = <a href="../sui/table.md#sui_table_borrow_mut">table::borrow_mut</a>(levels, price);
    vector::push_back(&<b>mut</b> level.order_ids, order_id);
    level.total_quantity = level.total_quantity + quantity;
    // Update pool statistics
    <b>if</b> (is_bid) {
        pool.total_bid_quantity = pool.total_bid_quantity + quantity;
    } <b>else</b> {
        pool.total_ask_quantity = pool.total_ask_quantity + quantity;
    };
    pool.total_orders = pool.total_orders + 1;
}
</code></pre>



</details>

<a name="sui_dex_hybrid_update_order_quantity"></a>

## Function `update_order_quantity`

Update order quantity after match


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_update_order_quantity">update_order_quantity</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, order_id: u64, filled_qty: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_update_order_quantity">update_order_quantity</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    order_id: u64,
    filled_qty: u64,
) {
    <b>if</b> (!<a href="../sui/table.md#sui_table_contains">table::contains</a>(&pool.order_index, order_id)) <b>return</b>;
    <b>let</b> order_info = <a href="../sui/table.md#sui_table_borrow_mut">table::borrow_mut</a>(&<b>mut</b> pool.order_index, order_id);
    order_info.quantity = order_info.quantity - filled_qty;
    order_info.filled_quantity = order_info.filled_quantity + filled_qty;
    // Remove <b>if</b> fully filled
    <b>if</b> (order_info.quantity == 0) {
        <b>let</b> info = *order_info;
        <a href="../sui/dex_hybrid.md#sui_dex_hybrid_remove_order_from_level">remove_order_from_level</a>(pool, order_id, info.price, info.is_bid);
        <a href="../sui/table.md#sui_table_remove">table::remove</a>(&<b>mut</b> pool.order_index, order_id);
    };
}
</code></pre>



</details>

<a name="sui_dex_hybrid_remove_order_from_level"></a>

## Function `remove_order_from_level`

Remove order from price level


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_remove_order_from_level">remove_order_from_level</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">sui::dex_hybrid::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, order_id: u64, price: u64, is_bid: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_remove_order_from_level">remove_order_from_level</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    order_id: u64,
    price: u64,
    is_bid: bool,
) {
    // Get order quantity before removing
    <b>let</b> quantity = <b>if</b> (<a href="../sui/table.md#sui_table_contains">table::contains</a>(&pool.order_index, order_id)) {
        <a href="../sui/table.md#sui_table_borrow">table::borrow</a>(&pool.order_index, order_id).quantity
    } <b>else</b> {
        0
    };
    <b>let</b> levels = <b>if</b> (is_bid) { &<b>mut</b> pool.bid_levels } <b>else</b> { &<b>mut</b> pool.ask_levels };
    <b>if</b> (!<a href="../sui/table.md#sui_table_contains">table::contains</a>(levels, price)) <b>return</b>;
    <b>let</b> level = <a href="../sui/table.md#sui_table_borrow_mut">table::borrow_mut</a>(levels, price);
    <b>let</b> (found, idx) = vector::index_of(&level.order_ids, &order_id);
    <b>if</b> (found) {
        vector::remove(&<b>mut</b> level.order_ids, idx);
        level.total_quantity = level.total_quantity - quantity;
        // Update pool statistics
        <b>if</b> (is_bid) {
            pool.total_bid_quantity = pool.total_bid_quantity - quantity;
        } <b>else</b> {
            pool.total_ask_quantity = pool.total_ask_quantity - quantity;
        };
        // Remove level <b>if</b> empty
        <b>if</b> (vector::is_empty(&level.order_ids)) {
            <b>let</b> _removed_level = <a href="../sui/table.md#sui_table_remove">table::remove</a>(levels, price);
            <b>let</b> prices = <b>if</b> (is_bid) { &<b>mut</b> pool.bid_prices } <b>else</b> { &<b>mut</b> pool.ask_prices };
            <b>let</b> (found_price, price_idx) = vector::index_of(prices, &price);
            <b>if</b> (found_price) {
                vector::remove(prices, price_idx);
            };
        };
    };
}
</code></pre>



</details>

<a name="sui_dex_hybrid_insert_price_sorted"></a>

## Function `insert_price_sorted`

Insert price into sorted vector


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_insert_price_sorted">insert_price_sorted</a>(prices: &<b>mut</b> vector&lt;u64&gt;, price: u64, descending: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../sui/dex_hybrid.md#sui_dex_hybrid_insert_price_sorted">insert_price_sorted</a>(prices: &<b>mut</b> vector&lt;u64&gt;, price: u64, descending: bool) {
    <b>let</b> len = vector::length(prices);
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; len) {
        <b>let</b> existing = *vector::borrow(prices, i);
        <b>let</b> should_insert = <b>if</b> (descending) {
            price &gt; existing
        } <b>else</b> {
            price &lt; existing
        };
        <b>if</b> (should_insert) {
            vector::insert(prices, price, i);
            <b>return</b>
        };
        i = i + 1;
    };
    vector::push_back(prices, price);
}
</code></pre>



</details>
