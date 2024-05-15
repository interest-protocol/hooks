#[test_only]
module hooks::swap_burn_tests {
 use std::string;
 use std::type_name;

 use sui::test_utils::{destroy, assert_eq};
 use sui::coin::{Coin, mint_for_testing as mint, burn_for_testing as burn};

 use clamm::eth::ETH;
 use clamm::usdc::USDC;
 use clamm::lp_coin::LP_COIN;
 use clamm::interest_pool::{Self, HooksBuilder};
 use clamm::interest_clamm_volatile as volatile;

 use hooks::admin;
 use hooks::test_runner;
 use hooks::assert_hooks_builder;
 use hooks::swap_burn::{Self, BurnHook};

 use fun string::utf8 as vector.utf8;
 use fun test_runner::swap_burn_swap as test_runner::TestRunner.swap;
 use fun assert_hooks_builder::start_swap as HooksBuilder.assert_start_swap;

 const TEN_PERCENT: u64 = 100_000_000;

 public struct Witness has drop {}

 #[test]
 fun test_add() {
  let mut runner = test_runner::start();

  let hook_admin = runner.swap_burn_add<USDC>(TEN_PERCENT);

  assert_eq(hook_admin.pool(), runner.pool().addy());

  runner
  .hooks_builder()
  .assert_start_swap<BurnHook>();

  runner.add_hooks();

  assert_eq(swap_burn::fee(runner.pool()), TEN_PERCENT);
  assert_eq(swap_burn::coin_type(runner.pool()), type_name::get<USDC>());

  hook_admin.destroy();
  runner.end();  
 }

 #[test]
 fun test_swap() {
  let mut runner = test_runner::start();

  runner.swap_burn_add<USDC>(TEN_PERCENT).destroy();

  runner.add_hooks();

  let request_in = runner.pool().start_swap();

  let coin_in = mint<USDC>(1000, runner.scenario().ctx());

  let (request_out, coin_out) = runner.swap<USDC, ETH>(request_in, coin_in);
  
  destroy(coin_out);

  runner.pool_finish(request_out);

  runner.scenario().next_tx(@0x0);

  let burnt_coin = runner.scenario().take_from_address<Coin<USDC>>(@0x0);

  // 10%
  assert_eq(burn(burnt_coin), 100);

  runner.scenario().next_tx(@0x0);

  let mut pool = runner.take_pool();

  let (quote_amount_out, _) = volatile::quote_swap<ETH, USDC, LP_COIN>(&mut pool, runner.clock(), 300);

  runner.return_pool(pool);

  let request_in = runner.pool().start_swap();

  let coin_in = mint<ETH>(300, runner.scenario().ctx());

  let (request_out, coin_out) = runner.swap<ETH, USDC>(request_in, coin_in);

  // No burn
  assert_eq(burn(coin_out), quote_amount_out);

  runner.pool_finish(request_out);

  runner.end();    
 }

 #[test]
 fun test_set_fee() {
  let mut runner = test_runner::start();

  let hook_admin = runner.swap_burn_add<USDC>(TEN_PERCENT);

  runner
  .hooks_builder()
  .assert_start_swap<BurnHook>();

  runner.add_hooks();

  assert_eq(swap_burn::fee(runner.pool()), TEN_PERCENT);

  swap_burn::set_fee(&hook_admin, runner.pool(), TEN_PERCENT * 2);

  assert_eq(swap_burn::fee(runner.pool()), TEN_PERCENT * 2);

  hook_admin.destroy();
  runner.end();    
 }

 #[test]
 #[expected_failure(abort_code = hooks::swap_burn::EFeeIsTooHigh)]
 fun test_add_fee_is_too_high() {
  let mut runner = test_runner::start();

  // Max is 50% inclusive
  runner.swap_burn_add<USDC>((TEN_PERCENT * 5 ) + 1).destroy();

  runner.end();    
 }

 #[test]
 #[expected_failure(abort_code = hooks::swap_burn::EHooksBuilderPoolMismatch)]
 fun test_add_hooks_builder_pool_mismatch() {
  let mut runner = test_runner::start();

  let (wrong_pool, pool_admin, wrong_hooks_builder, lp_coin) = runner.new_pool();
  let mut hooks_builder = runner.take_hooks_builder();

  let hook_admin = swap_burn::add<USDC>(&wrong_pool, &mut hooks_builder, 1, runner.scenario().ctx());

  hook_admin.destroy();

  destroy(wrong_pool);
  destroy(pool_admin);
  destroy(hooks_builder);
  destroy(wrong_hooks_builder);
  destroy(lp_coin);
  runner.end();  
 }  

 #[test]
 #[expected_failure(abort_code = hooks::swap_burn::EInvalidCoinType)]
 fun test_add_invalid_coin_type() {
  let mut runner = test_runner::start();

  runner.swap_burn_add<LP_COIN>(TEN_PERCENT).destroy();

  runner.end();    
 } 

 #[test]
 #[expected_failure(abort_code = hooks::swap_burn::EInvalidRequestName)] 
 fun test_swap_invalid_request_name() {
  let mut runner = test_runner::start();

  let (mut wrong_pool, pool_admin, mut wrong_hooks_builder, lp_coin) = runner.new_pool();

  runner.swap_burn_add<USDC>(TEN_PERCENT).destroy();

  wrong_hooks_builder.add_rule(interest_pool::start_remove_liquidity_name().utf8(), Witness {});

  wrong_pool.add_hooks(wrong_hooks_builder);

  let invalid_request = wrong_pool.start_remove_liquidity();

  let coin_in = mint(100, runner.scenario().ctx()); 

  let (request_out, coin_out) = runner.swap<ETH, USDC>(invalid_request, coin_in);

  destroy(request_out);
  destroy(coin_out);
  destroy(wrong_pool);
  destroy(pool_admin);
  destroy(lp_coin);
  runner.end();   
 }

 #[test]
 #[expected_failure(abort_code = hooks::swap_burn::EInvalidRequestPool)] 
 fun test_swap_invalid_request_pool() {
  let mut runner = test_runner::start();

  let (mut wrong_pool, pool_admin, wrong_hooks_builder, lp_coin) = runner.new_pool();

  runner.swap_burn_add<USDC>(TEN_PERCENT).destroy();

  wrong_pool.add_hooks(wrong_hooks_builder);
  runner.add_hooks();

  let request_in = runner.pool().start_swap();

  let clock = runner.take_clock();

  let ctx = runner.scenario().ctx();

  let coin_in = mint(100, ctx); 

  let (request_out, coin_out) = swap_burn::swap<ETH, USDC, LP_COIN>(&mut wrong_pool, &clock, request_in, coin_in, 0, ctx);

  destroy(clock);
  destroy(request_out);
  destroy(coin_out);
  destroy(wrong_pool);
  destroy(pool_admin);
  destroy(lp_coin);
  runner.end();   
 } 

 #[test]
 #[expected_failure(abort_code = hooks::swap_burn::EFeeIsTooHigh)]
 fun test_set_fee_fee_is_too_high() {
  let mut runner = test_runner::start();

  let hook_admin = runner.swap_burn_add<USDC>(TEN_PERCENT);

  runner.add_hooks();

  swap_burn::set_fee(&hook_admin, runner.pool(), (TEN_PERCENT * 5) + 1);

  hook_admin.destroy();
  runner.end();   
 }

 #[test]
 #[expected_failure]
 fun test_set_fee_invalid_admin() {
  let mut runner = test_runner::start();

  runner.swap_burn_add<USDC>(TEN_PERCENT).destroy();

  runner
  .hooks_builder()
  .assert_start_swap<BurnHook>();

  runner.add_hooks();

  let invalid_admin = admin::new_for_testing(@0x5, runner.scenario().ctx());

  swap_burn::set_fee(&invalid_admin, runner.pool(), TEN_PERCENT * 2);

  invalid_admin.destroy();
  runner.end();   
 }
}