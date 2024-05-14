#[test_only]
module hooks::test_runner {
 use sui::test_utils;
 use sui::clock::{Self, Clock};
 use sui::test_scenario::{Self, Scenario};
 use sui::balance::create_supply_for_testing;
 use sui::coin::{Coin, mint_for_testing as mint};

 use suitears::coin_decimals::CoinDecimals;

 use clamm::eth::ETH;
 use clamm::usdc::USDC;
 use clamm::lp_coin::LP_COIN; 
 use clamm::curves::Volatile;
 use clamm::pool_admin::PoolAdmin;
 use clamm::interest_clamm_volatile;
 use clamm::amm_test_utils::setup_dependencies;
 use clamm::interest_pool::{InterestPool, HooksBuilder, Request}; 

 use hooks::blocklist;
 use hooks::whitelist;
 use hooks::admin::Admin;

 const ADMIN: address = @0xa117ce;
 const ETH_DECIMALS_SCALAR: u64 = 1_000_000_000; 
 const USDC_DECIMALS_SCALAR: u64 = 1_000_000; 
 const A: u256  = 36450000;
 const GAMMA: u256 = 70000000000000;
 const MID_FEE: u256 = 4000000;
 const OUT_FEE: u256 = 40000000;
 const ALLOWED_EXTRA_PROFIT: u256 = 2000000000000;
 const GAMMA_FEE: u256 = 10000000000000000;
 const ADJUSTMENT_STEP: u256 = 1500000000000000;
 const MA_TIME: u256 = 600_000; // 10 minutes
 const ETH_INITIAL_PRICE: u256 = 1500 * 1_000_000_000_000_000_000;

 public struct TestRunner {
  clock: Clock,
  scenario: Scenario,
  pool: vector<InterestPool<Volatile>>,
  coin_decimals: CoinDecimals,
  pool_admin: PoolAdmin,
  hooks_builder: vector<HooksBuilder>,
  lp_coin: Coin<LP_COIN>
 }

 public fun start(): TestRunner {
  let mut scenario = test_scenario::begin(ADMIN);

  let scenario_mut = &mut scenario;

  let clock = clock::create_for_testing(scenario_mut.ctx());  

  setup_dependencies(scenario_mut);

  scenario_mut.next_tx(ADMIN);

  let coin_decimals = scenario_mut.take_shared<CoinDecimals>();

  let (pool, pool_admin, hooks_builder, lp_coin) = new_pool_impl(&clock, &coin_decimals, scenario_mut);

  TestRunner {
   clock,
   scenario,
   pool: vector[pool],
   coin_decimals,
   pool_admin,
   hooks_builder: vector[hooks_builder],
   lp_coin
  }
 }

 public fun end(self: TestRunner) {
  test_utils::destroy(self);
 }

 public fun clock(self: &mut TestRunner): &mut Clock {
  &mut self.clock
 }

 public fun scenario(self: &mut TestRunner): &mut Scenario {
  &mut self.scenario
 }

 public fun pool(self: &mut TestRunner): &mut InterestPool<Volatile> {
  &mut self.pool[0]
 }

 public fun pop_pool(self: &mut TestRunner): InterestPool<Volatile> {
  self.pool.pop_back()
 }

 public fun coin_decimals(self: &mut TestRunner): &mut CoinDecimals {
  &mut self.coin_decimals
 }

 public fun pool_admin(self: &mut TestRunner): &mut PoolAdmin {
  &mut self.pool_admin
 }

 public fun hooks_builder(self: &mut TestRunner): &mut HooksBuilder {
  &mut self.hooks_builder[0]
 }

 public fun pop_hooks_builder(self: &mut TestRunner): HooksBuilder {
  self.hooks_builder.pop_back()
 }

 public fun lp_coin(self: &mut TestRunner): &mut Coin<LP_COIN> {
  &mut self.lp_coin
 }

 public fun blocklist_add(self: &mut TestRunner): Admin {
  blocklist::add(&self.pool[0], &mut self.hooks_builder[0], self.scenario.ctx())
 }

 public fun whitelist_add(self: &mut TestRunner): Admin {
  whitelist::add(&self.pool[0], &mut self.hooks_builder[0], self.scenario.ctx())
 } 

 public fun blocklist_approve(self: &mut TestRunner, request: &mut Request) {
  blocklist::approve(&self.pool[0], request, self.scenario.ctx());
 }

 public fun whitelist_approve(self: &mut TestRunner, request: &mut Request) {
  whitelist::approve(&self.pool[0], request, self.scenario.ctx());
 }

 public fun blocklist_is_blocklisted(self: &mut TestRunner, user: address): bool {
  blocklist::is_blocklisted(&self.pool[0], user)
 }

 public fun whitelist_is_whitelisted(self: &mut TestRunner, user: address): bool {
  whitelist::is_whitelisted(&self.pool[0], user)
 }

 public fun add_hooks(self: &mut TestRunner): &mut TestRunner {
  let hooks_builder = self.hooks_builder.pop_back();
  self.pool[0].add_hooks(hooks_builder);
  self
 }

 public fun new_pool(self: &mut TestRunner): (InterestPool<Volatile>, PoolAdmin, HooksBuilder, Coin<LP_COIN>) {
  new_pool_impl(&self.clock, &self.coin_decimals, &mut self.scenario)
 }

 fun new_pool_impl(
  clock: &Clock, 
  coin_decimals: &CoinDecimals,
  test: &mut Scenario, 
 ): (InterestPool<Volatile>, PoolAdmin, HooksBuilder, Coin<LP_COIN>) {
  interest_clamm_volatile::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      clock,
      coin_decimals,
      mint(30_000 * USDC_DECIMALS_SCALAR, test.ctx()),
      mint(20 * ETH_DECIMALS_SCALAR, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      vector[A, GAMMA],
      vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
      ETH_INITIAL_PRICE,
      vector[MID_FEE, OUT_FEE, GAMMA_FEE],
      test.ctx()
    )
 }
}