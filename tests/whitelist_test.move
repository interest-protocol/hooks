#[test_only]
module hooks::whitelist_tests {
 use std::type_name;

 use sui::test_utils::{destroy, assert_eq};

 use clamm::interest_pool::HooksBuilder;

 use hooks::test_runner;
 use hooks::assert_hooks_builder;
 use hooks::whitelist::{Self, WhitelistHook};

 use fun assert_hooks_builder::start_swap as HooksBuilder.assert_start_swap;
 use fun assert_hooks_builder::start_add_liquidity as HooksBuilder.assert_start_add_liquidity;


 #[test]
 public fun test_add() {
  let mut runner = test_runner::start();

  let hook_admin = runner.whitelist_add();

  assert_eq(hook_admin.pool(), runner.pool().addy());

  runner
  .hooks_builder()
  .assert_start_swap<WhitelistHook>()
  .assert_start_add_liquidity<WhitelistHook>();

  hook_admin.destroy();

  runner.end();
 } 

 #[test]
 public fun test_approve() {
  let mut runner = test_runner::start();

  let hook_admin = runner.whitelist_add();

  let mut request = runner
  .add_hooks()
  .pool()
  .start_swap();

  let sender = runner.scenario().ctx().sender();

  whitelist::add_user(&hook_admin, runner.pool(), sender);

  runner.whitelist_approve(&mut request);

  let mut request2 = runner.pool().start_add_liquidity();

  runner.whitelist_approve(&mut request2);

  let sender = runner.scenario().ctx().sender();

  assert_eq(runner.whitelist_is_whitelisted(sender), true);

  assert_eq(request.approvals().contains(&type_name::get<WhitelistHook>()), true);
  assert_eq(request2.approvals().contains(&type_name::get<WhitelistHook>()), true);
  
  hook_admin.destroy();
  destroy(request2);
  destroy(request);
  runner.end();
 } 

 #[test]
 fun test_admin_rights() {
  let mut runner = test_runner::start();

  // Adds the hook to the builder
  let hook_admin = runner.whitelist_add();

  // Adds the hook tot he pool
  runner.add_hooks();

  let sender = runner.scenario().ctx().sender();

  assert_eq(runner.whitelist_is_whitelisted(sender), false);

  whitelist::add_user(&hook_admin, runner.pool(), sender);

  assert_eq(runner.whitelist_is_whitelisted(sender), true);

  whitelist::remove_user(&hook_admin, runner.pool(), sender);

  assert_eq(runner.whitelist_is_whitelisted(sender), false);

  hook_admin.destroy();
  runner.end();  
 } 

 #[test]
 #[expected_failure(abort_code = hooks::whitelist::EHooksBuilderPoolMismatch)]
 fun test_add_hooks_builder_pool_mismatch() {
  let mut runner = test_runner::start();

  let (wrong_pool, pool_admin, wrong_hooks_builder, lp_coin) = runner.new_pool();
  let mut hooks_builder = runner.pop_hooks_builder();

  let hook_admin = whitelist::add(&wrong_pool, &mut hooks_builder, runner.scenario().ctx());

  hook_admin.destroy();

  destroy(wrong_pool);
  destroy(pool_admin);
  destroy(hooks_builder);
  destroy(wrong_hooks_builder);
  destroy(lp_coin);
  runner.end();  
 } 

 #[test]
 #[expected_failure(abort_code = hooks::whitelist::EInvalidRequestPool)]
 fun test_approve_invalid_request_pool() {
  let mut runner = test_runner::start();

  let (wrong_pool, pool_admin, wrong_hooks_builder, lp_coin) = runner.new_pool();

  runner.whitelist_add().destroy();

  let mut request = runner
  .add_hooks()
  .pool()
  .start_swap();

  whitelist::approve(&wrong_pool, &mut request, runner.scenario().ctx());

  destroy(request);
  destroy(wrong_pool);
  destroy(pool_admin);
  destroy(wrong_hooks_builder);
  destroy(lp_coin);
  runner.end();  
 } 

 #[test]
 #[expected_failure(abort_code = hooks::whitelist::ENotWhitelisted)]
 fun test_approve_not_whitelisted() {
  let mut runner = test_runner::start();

  // Adds the hook to the builder
  let hook_admin = runner.whitelist_add();

  let mut request = runner
  .add_hooks()
  .pool()
  .start_swap();

  runner.whitelist_approve(&mut request);

  hook_admin.destroy();
  destroy(request);
  runner.end();  
 } 
}