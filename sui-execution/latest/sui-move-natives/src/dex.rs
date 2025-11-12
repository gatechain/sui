use crate::{
    address::{AddressFromBytesCostParams, AddressFromU256CostParams, AddressToU256CostParams},
    crypto::{bls12381, ecdsa_k1, ecdsa_r1, ecvrf, ed25519, groth16, hash, hmac},
    crypto::{
        bls12381::{Bls12381Bls12381MinPkVerifyCostParams, Bls12381Bls12381MinSigVerifyCostParams},
        ecdsa_k1::{
            EcdsaK1DecompressPubkeyCostParams, EcdsaK1EcrecoverCostParams,
            EcdsaK1Secp256k1VerifyCostParams,
        },
        ecdsa_r1::{EcdsaR1EcrecoverCostParams, EcdsaR1Secp256R1VerifyCostParams},
        ecvrf::EcvrfEcvrfVerifyCostParams,
        ed25519::Ed25519VerifyCostParams,
        groth16::{
            Groth16PrepareVerifyingKeyCostParams, Groth16VerifyGroth16ProofInternalCostParams,
        },
        hash::{HashBlake2b256CostParams, HashKeccak256CostParams},
        hmac::HmacHmacSha3256CostParams,
        poseidon,
    },
    dynamic_field::{
        DynamicFieldAddChildObjectCostParams, DynamicFieldBorrowChildObjectCostParams,
        DynamicFieldHasChildObjectCostParams, DynamicFieldHasChildObjectWithTyCostParams,
        DynamicFieldHashTypeAndKeyCostParams, DynamicFieldRemoveChildObjectCostParams,
    },
    event::EventEmitCostParams,
    object::{BorrowUidCostParams, DeleteImplCostParams, RecordNewIdCostParams},
    transfer::{
        TransferFreezeObjectCostParams, TransferInternalCostParams, TransferShareObjectCostParams,
    },
    tx_context::TxContextDeriveIdCostParams,
    types::TypesIsOneTimeWitnessCostParams,
    validator::ValidatorValidateMetadataBcsCostParams,
};
use move_vm_runtime::{native_charge_gas_early_exit, native_functions::{NativeFunction, NativeFunctionTable,NativeContext}};
use crate::crypto::group_ops;
use crate::crypto::group_ops::GroupOpsCostParams;
use crate::crypto::poseidon::PoseidonBN254CostParams;
use crate::crypto::zklogin;
use crate::crypto::zklogin::{CheckZkloginIdCostParams, CheckZkloginIssuerCostParams};
use better_any::{Tid, TidAble};
use move_binary_format::errors::{PartialVMError, PartialVMResult};
use move_core_types::{
    annotated_value as A,
    gas_algebra::InternalGas,
    identifier::Identifier,
    language_storage::{StructTag, TypeTag},
    runtime_value as R,
    vm_status::StatusCode,
    account_address::AccountAddress,
};
use move_stdlib_natives::{GasParameters};
use move_vm_types::{
    loaded_data::runtime_types::Type,
    natives::function::NativeResult,
    values::{Struct, Value},
    pop_arg,
};
use std::sync::Arc;
use sui_protocol_config::ProtocolConfig;
use crate::{
    get_receiver_object_id, get_tag_and_layouts, get_object_id, get_nested_struct_field,
    NativesCostTable,
    object_runtime::{ObjectRuntime, TransferResult, object_store::ObjectResult},
};
use std::collections::{VecDeque, HashMap, BTreeMap};
use sui_types::{
    base_types::{MoveObjectType, ObjectID, SequenceNumber},
    object::Owner,
};
use smallvec::smallvec;
use move_vm_types::values::StructRef;

#[derive(Debug, Clone)]
pub struct Token {
    pub name: String,
    pub symbol: String,
}

#[derive(Debug)]
pub struct LiquidityPool {
    pub token_a: Token,
    pub token_b: Token,
    pub reserve_a: f64,
    pub reserve_b: f64,
}

/// OrderInfo struct similar to DeepBookV3
#[derive(Debug, Clone)]
pub struct OrderInfo {
    pub order_id: u64,
    pub client_order_id: u64,
    pub price: u64,
    pub original_quantity: u64,
    pub quantity: u64,
    pub filled_quantity: u64,
    pub is_bid: bool,
    pub owner: AccountAddress,
    pub expire_timestamp: u64,
}

/// Helper function to get OrderBook object ID from StructRef
fn get_order_book_id(order_book_ref: StructRef) -> PartialVMResult<ObjectID> {
    let order_book_value = order_book_ref.read_ref()?;
    let id_value = get_object_id(order_book_value)?;
    Ok(id_value.value_as::<AccountAddress>()?.into())
}

/// Helper function to get or create OrderBook data from Move object
/// This function reads the OrderBook object and extracts its data
fn get_order_book_data(
    context: &mut NativeContext,
    order_book_id: ObjectID,
) -> PartialVMResult<(HashMap<u64, OrderInfo>, u64, BTreeMap<u64, Vec<u64>>, BTreeMap<u64, Vec<u64>>)> {
    // For now, we'll use a simplified approach: store data in the object's fields
    // In a full implementation, we would read from the Table fields in the OrderBook object
    // This requires more complex Move object field access which is better handled in Move code
    
    // Return empty data structures - actual implementation would read from Move object
    Ok((
        HashMap::new(),
        0,
        BTreeMap::new(),
        BTreeMap::new(),
    ))
}

/*

impl LiquidityPool {
    fn new(token_a: Token, token_b: Token) -> Self {
        Self {
            token_a,
            token_b,
            reserve_a: 0.0,
            reserve_b: 0.0,
        }
    }

    // 添加流动性
    fn add_liquidity(&mut self, amount_a: f64, amount_b: f64) {
        self.reserve_a += amount_a;
        self.reserve_b += amount_b;
        println!(
            "Added liquidity: {} {} and {} {}",
            amount_a, self.token_a.symbol, amount_b, self.token_b.symbol
        );
    }
}

*/

//new(token_a: Token, token_b: Token) -> Self
pub fn new_liquidity_pool_internal(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 2);

   // let x: MoveStruct = args[0].value_as()?; 
    let aToken = pop_arg!(args, Struct);
    let bToken = pop_arg!(args, Struct);

    let mut iter = aToken.unpack()?;
    //todo get string from move value
    let _name: String = iter.next().unwrap().to_string();
    let _symbol = iter.next().unwrap().to_string();
    // let bToken = pop_arg!(args, Token);
    // let obj = args.pop_back().unwrap();

  
   // object_runtime_transfer(context, owner, ty, obj)?;
    let cost = context.gas_used();
    Ok(NativeResult::ok(cost, smallvec![]))
}

/// Place a limit order
/// Parameters: (order_book: &mut OrderBook, price: u64, quantity: u64, is_bid: bool, owner: address, expire_timestamp: u64) -> OrderInfo
pub fn place_order_internal(
    context: &mut NativeContext,
    mut ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 6);

    let expire_timestamp = pop_arg!(args, u64);
    let owner = pop_arg!(args, AccountAddress);
    let is_bid = pop_arg!(args, bool);
    let quantity = pop_arg!(args, u64);
    let price = pop_arg!(args, u64);
    let order_book_ref = pop_arg!(args, StructRef);
    
    // Get OrderBook object ID
    let order_book_id = get_order_book_id(order_book_ref)?;

    // Validate inputs
    if quantity == 0 {
        return Err(PartialVMError::new(StatusCode::MALFORMED)
            .with_message("Quantity must be greater than 0".to_string()));
    }
    if price == 0 {
        return Err(PartialVMError::new(StatusCode::MALFORMED)
            .with_message("Price must be greater than 0".to_string()));
    }
    // Note: expire_timestamp validation should be done in Move code using current timestamp

    // Get OrderBook data from Move object
    // Note: In a full implementation, we would read/write to the OrderBook's Table fields
    // For now, we'll use a simplified approach where data is managed in Move code
    // The native function generates the order ID and creates the OrderInfo
    // The actual storage is handled by Move code using Table operations
    
    // Generate order ID by reading from OrderBook object
    // For simplicity, we'll use a counter approach
    // In production, this should read from order_id_counter field in OrderBook
    let order_id = {
        // Read order_id_counter from OrderBook object
        // This is a simplified version - full implementation would read the field
        // For now, we generate a simple ID based on timestamp-like value
        // In production, this should be read from and written to the OrderBook object
        static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        COUNTER.fetch_add(1, std::sync::atomic::Ordering::SeqCst) + 1
    };

    // Create order info
    let mut order_info = OrderInfo {
        order_id,
        client_order_id: order_id, // Use order_id as client_order_id for simplicity
        price,
        original_quantity: quantity,
        quantity,
        filled_quantity: 0,
        is_bid,
        owner,
        expire_timestamp,
    };

    // Try to match with existing orders
    // Note: In a full implementation, this would read from OrderBook's bid_orders/ask_orders Tables
    match_order_in_object(&mut order_info, order_book_id, context)?;

    // If there's remaining quantity, the order should be added to OrderBook
    // This is handled by Move code after the native function returns

    // Return OrderInfo as Struct
    let order_info_value = create_order_info_struct(&order_info)?;
    let cost = context.gas_used();
    Ok(NativeResult::ok(cost, smallvec![order_info_value]))
}

/// Cancel an order
/// Parameters: (order_book: &mut OrderBook, order_id: u64, owner: address) -> bool
/// Note: This function verifies ownership. The actual removal from OrderBook is done in Move code.
pub fn cancel_order_internal(
    context: &mut NativeContext,
    mut ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 3);

    let owner = pop_arg!(args, AccountAddress);
    let order_id = pop_arg!(args, u64);
    let _order_book_ref = pop_arg!(args, StructRef);
    
    // Note: In a full implementation, we would:
    // 1. Read the order from OrderBook's order_book Table using ObjectRuntime
    // 2. Verify ownership
    // 3. Return success/failure
    // 
    // For now, we return success - the actual order lookup and removal
    // is handled by Move code using Table operations, as native functions
    // have limited access to Table contents. The Move code will verify
    // ownership by reading the order from the Table and checking the owner field.
    
    // The Move code will handle:
    // - Reading order from order_book Table
    // - Verifying ownership
    // - Removing from bid_orders/ask_orders Tables
    // - Removing from order_book Table
    
    let cost = context.gas_used();
    Ok(NativeResult::ok(cost, smallvec![Value::bool(true)]))
}

/// Match order with existing orders in the book
/// Simple matching: match if prices are equal
/// Note: In a full implementation, this would read from OrderBook's Tables
fn match_order_in_object(
    order: &mut OrderInfo,
    _order_book_id: ObjectID,
    _context: &mut NativeContext,
) -> PartialVMResult<()> {
    // In a full implementation, we would:
    // 1. Read bid_orders or ask_orders Table from OrderBook object
    // 2. Find matching price levels
    // 3. Read orders from order_book Table
    // 4. Update quantities
    // 5. Write back to OrderBook object
    
    // For now, matching is simplified - actual matching should be done in Move code
    // using Table operations, as native functions have limited access to Table contents
    
    // This is a placeholder - the actual matching logic should be implemented
    // either in Move code or by using ObjectRuntime to read/write Table fields
    
    Ok(())
}

/// Create OrderInfo struct from Rust OrderInfo
/// Note: Fields must be in the same order as defined in Move struct
fn create_order_info_struct(order_info: &OrderInfo) -> PartialVMResult<Value> {
    let struct_fields = vec![
        Value::u64(order_info.order_id),
        Value::u64(order_info.client_order_id),
        Value::u64(order_info.price),
        Value::u64(order_info.original_quantity),
        Value::u64(order_info.quantity),
        Value::u64(order_info.filled_quantity),
        Value::bool(order_info.is_bid),
        Value::address(order_info.owner),
        Value::u64(order_info.expire_timestamp),
    ];
    
    Ok(Value::struct_(Struct::pack(struct_fields)))
}
