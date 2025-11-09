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
use move_stdlib_natives::{GasParameters, NurseryGasParameters};
use move_vm_types::{
    loaded_data::runtime_types::Type,
    natives::function::NativeResult,
    values::{Struct, Value},
    pop_arg,
};
use std::sync::Arc;
use sui_protocol_config::ProtocolConfig;
use crate::{
    get_receiver_object_id, get_tag_and_layouts,
    NativesCostTable,
    object_runtime::{ObjectRuntime, TransferResult},
};
use std::collections::VecDeque;
use sui_types::{
    base_types::{MoveObjectType, ObjectID, SequenceNumber},
    object::Owner,
};
use smallvec::smallvec;

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
    mut ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 2);

   // let x: MoveStruct = args[0].value_as()?; 
    let aToken = pop_arg!(args, Struct);
    let bToken = pop_arg!(args, Struct);
    println!("atoken {:?}", aToken);
    println!("btoken {:?}", bToken);
   // let bToken = pop_arg!(args, Token);
   // let obj = args.pop_back().unwrap();

  
   // object_runtime_transfer(context, owner, ty, obj)?;
    let cost = context.gas_used();
    Ok(NativeResult::ok(cost, smallvec![]))
}
