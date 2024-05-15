module hooks::swap_burn {
  // === Imports ===
  use std::string;
  use std::type_name::{Self, TypeName};
  
  use sui::coin::Coin;
  use sui::clock::Clock;

  use clamm::curves::Volatile;
  use clamm::interest_clamm_volatile::swap_with_hooks;
  use clamm::interest_pool::{Self, InterestPool, HooksBuilder, Request};

  use suitears::math64::mul_div_down;

  use hooks::admin::{Self, Admin};

  // === Errors ===

  const EFeeIsTooHigh: u64 = 0;
  const EInvalidRequestName: u64 = 1;
  const EInvalidRequestPool: u64 = 3;
  const EInvalidCoinType: u64 = 4;
  const EHooksBuilderPoolMismatch: u64 = 5;

  // === Constants ===

  // @dev 1e9.
  const PRECISION: u64 = 1_000_000_000;

  // @dev The maximum fee is 50%, which is represented by 0.5e9. 
  const MAX_FEE: u64 = 500_000_000;

  // @dev System address where we will send the burnt coins.
  const BURN_ADDRESS: address = @0x0;

  // === Structs ===

  // @dev Witness to indicate that the {InterestPool} has this hook.
  public struct BurnHook has drop {}

  public struct FeeData has store {
   value: u64,
   coin_type: TypeName
  }

  // === Method Aliases ===

  use fun mul_div_down as u64.mul_div;
  use fun string::utf8 as vector.utf8;

  // === Public-Mutative Functions ===

  public fun add<CoinType>(pool: &InterestPool<Volatile>, hooks_builder: &mut HooksBuilder, value: u64, ctx: &mut TxContext): Admin {
    assert!(MAX_FEE >= value, EFeeIsTooHigh);
    assert!(pool.addy() == hooks_builder.pool_address_(), EHooksBuilderPoolMismatch);

    let coin_type = type_name::get<CoinType>();

    assert!(pool.coins().contains(&coin_type), EInvalidCoinType);

    hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), BurnHook {});
    hooks_builder.add_rule_config(BurnHook {}, FeeData { value, coin_type });

    admin::new(pool.addy(), ctx)
  }

  public fun swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    mut request: Request,
    mut coin_in: Coin<CoinIn>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): (Request, Coin<CoinOut>) {
    approve(pool, &mut request, &mut coin_in, ctx);

    swap_with_hooks<CoinIn, CoinOut, LpCoin>(pool, clock, request, coin_in, min_amount, ctx)
  }

  // === Public-View Functions ===

  public fun fee(pool: &InterestPool<Volatile>): u64 {
    pool.config<Volatile, BurnHook, FeeData>().value
  }

  public fun coin_type(pool: &InterestPool<Volatile>): TypeName {
    pool.config<Volatile, BurnHook, FeeData>().coin_type
  }

  // === Admin Functions ===

  public fun set_fee(admin: &Admin, pool: &mut InterestPool<Volatile>, value: u64) {
    assert!(MAX_FEE >= value, EFeeIsTooHigh);
    admin.assert_pool(pool.addy());

    let fee_data = pool.config_mut<Volatile, BurnHook, FeeData>(BurnHook {});

    fee_data.value = value;
  }

  // === Public-Package Functions ===

  // === Private Functions ===

  fun approve<CoinType>(pool: &InterestPool<Volatile>, request: &mut Request, coin_in: &mut Coin<CoinType>, ctx: &mut TxContext) {
    assert!(request.name() == interest_pool::start_swap_name().utf8(), EInvalidRequestName);
    assert!(request.pool_address() == pool.addy(), EInvalidRequestPool);

    let fee_data = pool.config<Volatile, BurnHook, FeeData>();
    let coin_type = type_name::get<CoinType>();

    request.approve(BurnHook {});

    if (fee_data.coin_type != coin_type) return;

    let coin_value = coin_in.value();
    let burn_value = coin_value.mul_div(fee_data.value, PRECISION);

    transfer::public_transfer(coin_in.split(burn_value, ctx), BURN_ADDRESS);
  }

  // === Test Functions === 
}