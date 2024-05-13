#[test_only]
module hooks::blocklist_tests {
 use std::type_name;

 use sui::test_utils::{destroy, assert_eq};

 use clamm::interest_pool::HooksBuilder;

 use hooks::test_runner;
 use hooks::assert_hooks_builder;
 use hooks::blocklist::{Self, BlocklistHook};

 use fun assert_hooks_builder::start_swap as HooksBuilder.assert_start_swap;
 use fun assert_hooks_builder::start_add_liquidity as HooksBuilder.assert_start_add_liquidity;
 
 #[test]
 public fun test_add() {
  let mut runner = test_runner::start();

  let hook_admin = runner.blocklist_add();

  assert_eq(hook_admin.pool(), runner.pool().addy());

  runner
  .hooks_builder()
  .assert_start_swap<BlocklistHook>()
  .assert_start_add_liquidity<BlocklistHook>();

  hook_admin.destroy();

  runner.end();
 }

 #[test]
 public fun test_approve() {
  let mut runner = test_runner::start();

  runner.blocklist_add().destroy();

  let mut request = runner
  .add_hooks()
  .pool()
  .start_swap();

  runner.blocklist_approve(&mut request);

  let mut request2 = runner.pool().start_add_liquidity();

  runner.blocklist_approve(&mut request2);

  let sender = runner.scenario().ctx().sender();

  assert_eq(runner.blocklist_is_blocklisted(sender), false);

  assert_eq(request.approvals().contains(&type_name::get<BlocklistHook>()), true);
  assert_eq(request2.approvals().contains(&type_name::get<BlocklistHook>()), true);
  
  destroy(request2);
  destroy(request);
  runner.end();
 }

 #[test]
 fun test_admin_rights() {
  let mut runner = test_runner::start();

  // Adds the hook to the builder
  let hook_admin = runner.blocklist_add();

  // Adds the hook tot he pool
  runner.add_hooks();

  let sender = runner.scenario().ctx().sender();

  assert_eq(runner.blocklist_is_blocklisted(sender), false);

  blocklist::add_blocklist(&hook_admin, runner.pool(), sender);

  assert_eq(runner.blocklist_is_blocklisted(sender), true);

  blocklist::remove_blocklist(&hook_admin, runner.pool(), sender);

  assert_eq(runner.blocklist_is_blocklisted(sender), false);

  hook_admin.destroy();
  runner.end();  
 }
}