---
title: Module `sui::dex`
---

Production-grade order book storage framework using Move objects


-  [Struct `Order`](#sui_dex_Order)
-  [Struct `PriceLevel`](#sui_dex_PriceLevel)
-  [Struct `Pool`](#sui_dex_Pool)
-  [Struct `OrderIndex`](#sui_dex_OrderIndex)
-  [Struct `OrderCap`](#sui_dex_OrderCap)
-  [Struct `OrderPlaced`](#sui_dex_OrderPlaced)
-  [Struct `OrderCancelled`](#sui_dex_OrderCancelled)
-  [Constants](#@Constants_0)
-  [Function `create_pool`](#sui_dex_create_pool)
-  [Function `share_pool`](#sui_dex_share_pool)
-  [Function `place_order`](#sui_dex_place_order)
-  [Function `cancel_order`](#sui_dex_cancel_order)
-  [Function `add_order_to_pool`](#sui_dex_add_order_to_pool)
-  [Function `remove_order_from_pool`](#sui_dex_remove_order_from_pool)
-  [Function `get_best_bid`](#sui_dex_get_best_bid)
-  [Function `get_best_ask`](#sui_dex_get_best_ask)
-  [Function `get_depth_summary`](#sui_dex_get_depth_summary)
-  [Function `has_level`](#sui_dex_has_level)
-  [Function `get_level_quantity`](#sui_dex_get_level_quantity)
-  [Function `get_level_order_count`](#sui_dex_get_level_order_count)
-  [Function `order_id`](#sui_dex_order_id)
-  [Function `order_price`](#sui_dex_order_price)
-  [Function `order_quantity`](#sui_dex_order_quantity)
-  [Function `order_filled_quantity`](#sui_dex_order_filled_quantity)
-  [Function `order_is_bid`](#sui_dex_order_is_bid)
-  [Function `order_owner`](#sui_dex_order_owner)
-  [Function `pool_total_orders`](#sui_dex_pool_total_orders)
-  [Function `pool_next_order_id`](#sui_dex_pool_next_order_id)


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
<b>use</b> <a href="../sui/bcs.md#sui_bcs">sui::bcs</a>;
<b>use</b> <a href="../sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../sui/hash.md#sui_hash">sui::hash</a>;
<b>use</b> <a href="../sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
</code></pre>



<a name="sui_dex_Order"></a>

## Struct `Order`

Order - Each order is an independent owned object for parallel execution


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex.md#sui_dex_Order">Order</a> <b>has</b> key, store
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
<code><a href="../sui/dex.md#sui_dex_order_id">order_id</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>price: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>original_quantity: u64</code>
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
<dt>
<code>expire_timestamp: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>pool_id: <a href="../sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_PriceLevel"></a>

## Struct `PriceLevel`

PriceLevel - Orders at a specific price


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex.md#sui_dex_PriceLevel">PriceLevel</a> <b>has</b> store
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

<a name="sui_dex_Pool"></a>

## Struct `Pool`

Pool - Central order book as shared object


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;<b>phantom</b> BaseAsset, <b>phantom</b> QuoteAsset&gt; <b>has</b> key
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
<code>bid_levels: <a href="../sui/table.md#sui_table_Table">sui::table::Table</a>&lt;u64, <a href="../sui/dex.md#sui_dex_PriceLevel">sui::dex::PriceLevel</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>ask_levels: <a href="../sui/table.md#sui_table_Table">sui::table::Table</a>&lt;u64, <a href="../sui/dex.md#sui_dex_PriceLevel">sui::dex::PriceLevel</a>&gt;</code>
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
<code>order_index: <a href="../sui/table.md#sui_table_Table">sui::table::Table</a>&lt;u64, <a href="../sui/dex.md#sui_dex_OrderIndex">sui::dex::OrderIndex</a>&gt;</code>
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

<a name="sui_dex_OrderIndex"></a>

## Struct `OrderIndex`

Order index entry


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex.md#sui_dex_OrderIndex">OrderIndex</a> <b>has</b> <b>copy</b>, drop, store
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

<a name="sui_dex_OrderCap"></a>

## Struct `OrderCap`

Capability for order modification


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex.md#sui_dex_OrderCap">OrderCap</a> <b>has</b> key, store
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
<code><a href="../sui/dex.md#sui_dex_order_id">order_id</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>pool_id: <a href="../sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_OrderPlaced"></a>

## Struct `OrderPlaced`



<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex.md#sui_dex_OrderPlaced">OrderPlaced</a> <b>has</b> <b>copy</b>, drop
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
<code><a href="../sui/dex.md#sui_dex_order_id">order_id</a>: u64</code>
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

<a name="sui_dex_OrderCancelled"></a>

## Struct `OrderCancelled`



<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex.md#sui_dex_OrderCancelled">OrderCancelled</a> <b>has</b> <b>copy</b>, drop
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
<code><a href="../sui/dex.md#sui_dex_order_id">order_id</a>: u64</code>
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


<a name="sui_dex_EInvalidPrice"></a>

Invalid price error


<pre><code><b>const</b> <a href="../sui/dex.md#sui_dex_EInvalidPrice">EInvalidPrice</a>: u64 = 1;
</code></pre>



<a name="sui_dex_EInvalidQuantity"></a>

Invalid quantity error


<pre><code><b>const</b> <a href="../sui/dex.md#sui_dex_EInvalidQuantity">EInvalidQuantity</a>: u64 = 2;
</code></pre>



<a name="sui_dex_EUnauthorized"></a>

Unauthorized access


<pre><code><b>const</b> <a href="../sui/dex.md#sui_dex_EUnauthorized">EUnauthorized</a>: u64 = 3;
</code></pre>



<a name="sui_dex_create_pool"></a>

## Function `create_pool`

Create a new order book pool


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_create_pool">create_pool</a>&lt;BaseAsset, QuoteAsset&gt;(tick_size: u64, min_order_size: u64, ctx: &<b>mut</b> <a href="../sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_create_pool">create_pool</a>&lt;BaseAsset, QuoteAsset&gt;(
    tick_size: u64,
    min_order_size: u64,
    ctx: &<b>mut</b> TxContext
): <a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt; {
    <a href="../sui/dex.md#sui_dex_Pool">Pool</a> {
        id: <a href="../sui/object.md#sui_object_new">object::new</a>(ctx),
        next_order_id: 0,
        bid_levels: <a href="../sui/table.md#sui_table_new">table::new</a>(ctx),
        ask_levels: <a href="../sui/table.md#sui_table_new">table::new</a>(ctx),
        bid_prices: vector[],
        ask_prices: vector[],
        order_index: <a href="../sui/table.md#sui_table_new">table::new</a>(ctx),
        total_bid_quantity: 0,
        total_ask_quantity: 0,
        total_orders: 0,
        min_order_size,
        tick_size,
    }
}
</code></pre>



</details>

<a name="sui_dex_share_pool"></a>

## Function `share_pool`

Share pool for public access


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_share_pool">share_pool</a>&lt;BaseAsset, QuoteAsset&gt;(pool: <a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_share_pool">share_pool</a>&lt;BaseAsset, QuoteAsset&gt;(pool: <a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;) {
    <a href="../sui/transfer.md#sui_transfer_share_object">transfer::share_object</a>(pool);
}
</code></pre>



</details>

<a name="sui_dex_place_order"></a>

## Function `place_order`

Place a new order


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_place_order">place_order</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, price: u64, quantity: u64, is_bid: bool, expire_timestamp: u64, ctx: &<b>mut</b> <a href="../sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../sui/dex.md#sui_dex_Order">sui::dex::Order</a>, <a href="../sui/dex.md#sui_dex_OrderCap">sui::dex::OrderCap</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_place_order">place_order</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    price: u64,
    quantity: u64,
    is_bid: bool,
    expire_timestamp: u64,
    ctx: &<b>mut</b> TxContext
): (<a href="../sui/dex.md#sui_dex_Order">Order</a>, <a href="../sui/dex.md#sui_dex_OrderCap">OrderCap</a>) {
    <b>assert</b>!(price &gt; 0, <a href="../sui/dex.md#sui_dex_EInvalidPrice">EInvalidPrice</a>);
    <b>assert</b>!(quantity &gt;= pool.min_order_size, <a href="../sui/dex.md#sui_dex_EInvalidQuantity">EInvalidQuantity</a>);
    <b>assert</b>!(price % pool.tick_size == 0, <a href="../sui/dex.md#sui_dex_EInvalidPrice">EInvalidPrice</a>);
    <b>let</b> <a href="../sui/dex.md#sui_dex_order_id">order_id</a> = pool.next_order_id;
    pool.next_order_id = pool.next_order_id + 1;
    pool.total_orders = pool.total_orders + 1;
    <b>let</b> owner = ctx.sender();
    <b>let</b> pool_id = <a href="../sui/object.md#sui_object_id">object::id</a>(pool);
    <b>let</b> order = <a href="../sui/dex.md#sui_dex_Order">Order</a> {
        id: <a href="../sui/object.md#sui_object_new">object::new</a>(ctx),
        <a href="../sui/dex.md#sui_dex_order_id">order_id</a>,
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
    <b>if</b> (quantity &gt; 0) {
        <a href="../sui/dex.md#sui_dex_add_order_to_pool">add_order_to_pool</a>(pool, <a href="../sui/dex.md#sui_dex_order_id">order_id</a>, price, quantity, is_bid, owner);
    };
    <b>let</b> order_cap = <a href="../sui/dex.md#sui_dex_OrderCap">OrderCap</a> {
        id: <a href="../sui/object.md#sui_object_new">object::new</a>(ctx),
        <a href="../sui/dex.md#sui_dex_order_id">order_id</a>,
        pool_id,
    };
    <a href="../sui/event.md#sui_event_emit">event::emit</a>(<a href="../sui/dex.md#sui_dex_OrderPlaced">OrderPlaced</a> {
        pool_id,
        <a href="../sui/dex.md#sui_dex_order_id">order_id</a>,
        price,
        quantity,
        is_bid,
        owner,
    });
    (order, order_cap)
}
</code></pre>



</details>

<a name="sui_dex_cancel_order"></a>

## Function `cancel_order`

Cancel an order


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_cancel_order">cancel_order</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, order: <a href="../sui/dex.md#sui_dex_Order">sui::dex::Order</a>, order_cap: <a href="../sui/dex.md#sui_dex_OrderCap">sui::dex::OrderCap</a>, ctx: &<a href="../sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_cancel_order">cancel_order</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    order: <a href="../sui/dex.md#sui_dex_Order">Order</a>,
    order_cap: <a href="../sui/dex.md#sui_dex_OrderCap">OrderCap</a>,
    ctx: &TxContext
) {
    <b>let</b> <a href="../sui/dex.md#sui_dex_Order">Order</a> {
        id,
        <a href="../sui/dex.md#sui_dex_order_id">order_id</a>,
        price,
        quantity,
        is_bid,
        owner,
        pool_id,
        original_quantity: _,
        filled_quantity: _,
        expire_timestamp: _,
    } = order;
    <b>let</b> <a href="../sui/dex.md#sui_dex_OrderCap">OrderCap</a> {
        id: cap_id,
        <a href="../sui/dex.md#sui_dex_order_id">order_id</a>: cap_order_id,
        pool_id: cap_pool_id,
    } = order_cap;
    <b>assert</b>!(pool_id == <a href="../sui/object.md#sui_object_id">object::id</a>(pool), <a href="../sui/dex.md#sui_dex_EUnauthorized">EUnauthorized</a>);
    <b>assert</b>!(owner == ctx.sender(), <a href="../sui/dex.md#sui_dex_EUnauthorized">EUnauthorized</a>);
    <b>assert</b>!(<a href="../sui/dex.md#sui_dex_order_id">order_id</a> == cap_order_id, <a href="../sui/dex.md#sui_dex_EUnauthorized">EUnauthorized</a>);
    <b>assert</b>!(pool_id == cap_pool_id, <a href="../sui/dex.md#sui_dex_EUnauthorized">EUnauthorized</a>);
    <b>if</b> (quantity &gt; 0) {
        <a href="../sui/dex.md#sui_dex_remove_order_from_pool">remove_order_from_pool</a>(pool, <a href="../sui/dex.md#sui_dex_order_id">order_id</a>, price, quantity, is_bid);
    };
    <a href="../sui/event.md#sui_event_emit">event::emit</a>(<a href="../sui/dex.md#sui_dex_OrderCancelled">OrderCancelled</a> {
        pool_id,
        <a href="../sui/dex.md#sui_dex_order_id">order_id</a>,
        owner,
    });
    id.delete();
    cap_id.delete();
}
</code></pre>



</details>

<a name="sui_dex_add_order_to_pool"></a>

## Function `add_order_to_pool`



<pre><code><b>fun</b> <a href="../sui/dex.md#sui_dex_add_order_to_pool">add_order_to_pool</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, <a href="../sui/dex.md#sui_dex_order_id">order_id</a>: u64, price: u64, quantity: u64, is_bid: bool, owner: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../sui/dex.md#sui_dex_add_order_to_pool">add_order_to_pool</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    <a href="../sui/dex.md#sui_dex_order_id">order_id</a>: u64,
    price: u64,
    quantity: u64,
    is_bid: bool,
    owner: <b>address</b>,
) {
    <b>let</b> (levels, prices, total_qty) = <b>if</b> (is_bid) {
        (&<b>mut</b> pool.bid_levels, &<b>mut</b> pool.bid_prices, &<b>mut</b> pool.total_bid_quantity)
    } <b>else</b> {
        (&<b>mut</b> pool.ask_levels, &<b>mut</b> pool.ask_prices, &<b>mut</b> pool.total_ask_quantity)
    };
    // Create price level <b>if</b> needed
    <b>if</b> (!<a href="../sui/table.md#sui_table_contains">table::contains</a>(levels, price)) {
        <b>let</b> level = <a href="../sui/dex.md#sui_dex_PriceLevel">PriceLevel</a> {
            price,
            total_quantity: 0,
            order_ids: vector[],
        };
        <a href="../sui/table.md#sui_table_add">table::add</a>(levels, price, level);
        prices.push_back(price); // Simplified - should maintain sorted order
    };
    // Add order to level
    <b>let</b> level = <a href="../sui/table.md#sui_table_borrow_mut">table::borrow_mut</a>(levels, price);
    level.order_ids.push_back(<a href="../sui/dex.md#sui_dex_order_id">order_id</a>);
    level.total_quantity = level.total_quantity + quantity;
    *total_qty = *total_qty + quantity;
    // Add to index
    <a href="../sui/table.md#sui_table_add">table::add</a>(&<b>mut</b> pool.order_index, <a href="../sui/dex.md#sui_dex_order_id">order_id</a>, <a href="../sui/dex.md#sui_dex_OrderIndex">OrderIndex</a> { price, is_bid, owner });
}
</code></pre>



</details>

<a name="sui_dex_remove_order_from_pool"></a>

## Function `remove_order_from_pool`



<pre><code><b>fun</b> <a href="../sui/dex.md#sui_dex_remove_order_from_pool">remove_order_from_pool</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<b>mut</b> <a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, <a href="../sui/dex.md#sui_dex_order_id">order_id</a>: u64, price: u64, quantity: u64, is_bid: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../sui/dex.md#sui_dex_remove_order_from_pool">remove_order_from_pool</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<b>mut</b> <a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    <a href="../sui/dex.md#sui_dex_order_id">order_id</a>: u64,
    price: u64,
    quantity: u64,
    is_bid: bool,
) {
    <b>let</b> (levels, prices, total_qty) = <b>if</b> (is_bid) {
        (&<b>mut</b> pool.bid_levels, &<b>mut</b> pool.bid_prices, &<b>mut</b> pool.total_bid_quantity)
    } <b>else</b> {
        (&<b>mut</b> pool.ask_levels, &<b>mut</b> pool.ask_prices, &<b>mut</b> pool.total_ask_quantity)
    };
    <b>let</b> level = <a href="../sui/table.md#sui_table_borrow_mut">table::borrow_mut</a>(levels, price);
    <b>let</b> (found, index) = level.order_ids.index_of(&<a href="../sui/dex.md#sui_dex_order_id">order_id</a>);
    <b>if</b> (found) {
        level.order_ids.remove(index);
    };
    level.total_quantity = level.total_quantity - quantity;
    *total_qty = *total_qty - quantity;
    <a href="../sui/table.md#sui_table_remove">table::remove</a>(&<b>mut</b> pool.order_index, <a href="../sui/dex.md#sui_dex_order_id">order_id</a>);
    // Clean up empty level
    <b>if</b> (level.total_quantity == 0) {
        <b>let</b> (found_price, price_index) = prices.index_of(&price);
        <b>if</b> (found_price) {
            prices.remove(price_index);
        };
        <b>let</b> <a href="../sui/dex.md#sui_dex_PriceLevel">PriceLevel</a> { price: _, total_quantity: _, order_ids: _ } =
            <a href="../sui/table.md#sui_table_remove">table::remove</a>(levels, price);
    };
}
</code></pre>



</details>

<a name="sui_dex_get_best_bid"></a>

## Function `get_best_bid`

Get best bid price (returns 0 if empty)


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_best_bid">get_best_bid</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_best_bid">get_best_bid</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;
): u64 {
    <b>if</b> (pool.bid_prices.is_empty()) {
        0
    } <b>else</b> {
        *pool.bid_prices.<a href="../sui/borrow.md#sui_borrow">borrow</a>(0)
    }
}
</code></pre>



</details>

<a name="sui_dex_get_best_ask"></a>

## Function `get_best_ask`

Get best ask price (returns 0 if empty)


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_best_ask">get_best_ask</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_best_ask">get_best_ask</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;
): u64 {
    <b>if</b> (pool.ask_prices.is_empty()) {
        0
    } <b>else</b> {
        *pool.ask_prices.<a href="../sui/borrow.md#sui_borrow">borrow</a>(0)
    }
}
</code></pre>



</details>

<a name="sui_dex_get_depth_summary"></a>

## Function `get_depth_summary`

Get depth summary


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_depth_summary">get_depth_summary</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;): (u64, u64, u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_depth_summary">get_depth_summary</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
): (u64, u64, u64, u64) {
    (
        pool.total_bid_quantity,
        pool.total_ask_quantity,
        pool.bid_prices.length(),
        pool.ask_prices.length()
    )
}
</code></pre>



</details>

<a name="sui_dex_has_level"></a>

## Function `has_level`

Check if price level exists


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_has_level">has_level</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, price: u64, is_bid: bool): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_has_level">has_level</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    price: u64,
    is_bid: bool
): bool {
    <b>let</b> levels = <b>if</b> (is_bid) { &pool.bid_levels } <b>else</b> { &pool.ask_levels };
    <a href="../sui/table.md#sui_table_contains">table::contains</a>(levels, price)
}
</code></pre>



</details>

<a name="sui_dex_get_level_quantity"></a>

## Function `get_level_quantity`

Get level total quantity


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_level_quantity">get_level_quantity</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, price: u64, is_bid: bool): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_level_quantity">get_level_quantity</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    price: u64,
    is_bid: bool
): u64 {
    <b>let</b> levels = <b>if</b> (is_bid) { &pool.bid_levels } <b>else</b> { &pool.ask_levels };
    <b>if</b> (<a href="../sui/table.md#sui_table_contains">table::contains</a>(levels, price)) {
        <b>let</b> level = <a href="../sui/table.md#sui_table_borrow">table::borrow</a>(levels, price);
        level.total_quantity
    } <b>else</b> {
        0
    }
}
</code></pre>



</details>

<a name="sui_dex_get_level_order_count"></a>

## Function `get_level_order_count`

Get number of orders at price level


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_level_order_count">get_level_order_count</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;, price: u64, is_bid: bool): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_get_level_order_count">get_level_order_count</a>&lt;BaseAsset, QuoteAsset&gt;(
    pool: &<a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;,
    price: u64,
    is_bid: bool
): u64 {
    <b>let</b> levels = <b>if</b> (is_bid) { &pool.bid_levels } <b>else</b> { &pool.ask_levels };
    <b>if</b> (<a href="../sui/table.md#sui_table_contains">table::contains</a>(levels, price)) {
        <b>let</b> level = <a href="../sui/table.md#sui_table_borrow">table::borrow</a>(levels, price);
        level.order_ids.length()
    } <b>else</b> {
        0
    }
}
</code></pre>



</details>

<a name="sui_dex_order_id"></a>

## Function `order_id`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_id">order_id</a>(order: &<a href="../sui/dex.md#sui_dex_Order">sui::dex::Order</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_id">order_id</a>(order: &<a href="../sui/dex.md#sui_dex_Order">Order</a>): u64 { order.<a href="../sui/dex.md#sui_dex_order_id">order_id</a> }
</code></pre>



</details>

<a name="sui_dex_order_price"></a>

## Function `order_price`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_price">order_price</a>(order: &<a href="../sui/dex.md#sui_dex_Order">sui::dex::Order</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_price">order_price</a>(order: &<a href="../sui/dex.md#sui_dex_Order">Order</a>): u64 { order.price }
</code></pre>



</details>

<a name="sui_dex_order_quantity"></a>

## Function `order_quantity`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_quantity">order_quantity</a>(order: &<a href="../sui/dex.md#sui_dex_Order">sui::dex::Order</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_quantity">order_quantity</a>(order: &<a href="../sui/dex.md#sui_dex_Order">Order</a>): u64 { order.quantity }
</code></pre>



</details>

<a name="sui_dex_order_filled_quantity"></a>

## Function `order_filled_quantity`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_filled_quantity">order_filled_quantity</a>(order: &<a href="../sui/dex.md#sui_dex_Order">sui::dex::Order</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_filled_quantity">order_filled_quantity</a>(order: &<a href="../sui/dex.md#sui_dex_Order">Order</a>): u64 { order.filled_quantity }
</code></pre>



</details>

<a name="sui_dex_order_is_bid"></a>

## Function `order_is_bid`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_is_bid">order_is_bid</a>(order: &<a href="../sui/dex.md#sui_dex_Order">sui::dex::Order</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_is_bid">order_is_bid</a>(order: &<a href="../sui/dex.md#sui_dex_Order">Order</a>): bool { order.is_bid }
</code></pre>



</details>

<a name="sui_dex_order_owner"></a>

## Function `order_owner`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_owner">order_owner</a>(order: &<a href="../sui/dex.md#sui_dex_Order">sui::dex::Order</a>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_order_owner">order_owner</a>(order: &<a href="../sui/dex.md#sui_dex_Order">Order</a>): <b>address</b> { order.owner }
</code></pre>



</details>

<a name="sui_dex_pool_total_orders"></a>

## Function `pool_total_orders`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_pool_total_orders">pool_total_orders</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_pool_total_orders">pool_total_orders</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;): u64 {
    pool.total_orders
}
</code></pre>



</details>

<a name="sui_dex_pool_next_order_id"></a>

## Function `pool_next_order_id`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_pool_next_order_id">pool_next_order_id</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">sui::dex::Pool</a>&lt;BaseAsset, QuoteAsset&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_pool_next_order_id">pool_next_order_id</a>&lt;BaseAsset, QuoteAsset&gt;(pool: &<a href="../sui/dex.md#sui_dex_Pool">Pool</a>&lt;BaseAsset, QuoteAsset&gt;): u64 {
    pool.next_order_id
}
</code></pre>



</details>
