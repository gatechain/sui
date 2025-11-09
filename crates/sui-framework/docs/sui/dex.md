---
title: Module `sui::dex`
---



-  [Struct `Token`](#sui_dex_Token)
-  [Function `create_token`](#sui_dex_create_token)
-  [Function `new_liquidity_pool_internal_impl`](#sui_dex_new_liquidity_pool_internal_impl)


<pre><code><b>use</b> <a href="../std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../std/vector.md#std_vector">std::vector</a>;
</code></pre>



<a name="sui_dex_Token"></a>

## Struct `Token`

A coin of type <code>T</code> worth <code>value</code>. Transferable and storable


<pre><code><b>public</b> <b>struct</b> <a href="../sui/dex.md#sui_dex_Token">Token</a>
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>name: <a href="../std/string.md#std_string_String">std::string::String</a></code>
</dt>
<dd>
</dd>
<dt>
<code>symbol: <a href="../std/string.md#std_string_String">std::string::String</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="sui_dex_create_token"></a>

## Function `create_token`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_create_token">create_token</a>(name: <a href="../std/string.md#std_string_String">std::string::String</a>, symbol: <a href="../std/string.md#std_string_String">std::string::String</a>): <a href="../sui/dex.md#sui_dex_Token">sui::dex::Token</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_create_token">create_token</a>(name: string::String, symbol: string::String): <a href="../sui/dex.md#sui_dex_Token">Token</a> {
        <a href="../sui/dex.md#sui_dex_Token">Token</a> { name, symbol }
}
</code></pre>



</details>

<a name="sui_dex_new_liquidity_pool_internal_impl"></a>

## Function `new_liquidity_pool_internal_impl`



<pre><code><b>public</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_new_liquidity_pool_internal_impl">new_liquidity_pool_internal_impl</a>(tokena: <a href="../sui/dex.md#sui_dex_Token">sui::dex::Token</a>, tokenb: <a href="../sui/dex.md#sui_dex_Token">sui::dex::Token</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>native</b> <b>fun</b> <a href="../sui/dex.md#sui_dex_new_liquidity_pool_internal_impl">new_liquidity_pool_internal_impl</a>(tokena: <a href="../sui/dex.md#sui_dex_Token">Token</a>, tokenb: <a href="../sui/dex.md#sui_dex_Token">Token</a>);
</code></pre>



</details>
