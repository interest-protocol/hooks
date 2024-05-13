module hooks::blocklist {
  // === Imports ===
  use std::string;
  
  use sui::table::{Self, Table};

  use clamm::curves::Volatile;
  use clamm::interest_pool::{Self, InterestPool, HooksBuilder, Request};

  use hooks::admin::{Self, Admin};

  // === Errors ===

  const EHooksBuilderPoolMismatch: u64 = 0;
  const EInvalidRequestName: u64 = 1;
  const EBlocklisted: u64 = 2;
  const EInvalidRequestPool: u64 = 3;

  // === Constants ===

  // === Structs ===

  public struct BlocklistHook has drop {}

  public struct Blocklist has store {
    inner: Table<address, bool>
  }

  // === Method Aliases ===

  use fun string::utf8 as vector.utf8;

  // === Public-Mutative Functions ===

  public fun add(pool: &InterestPool<Volatile>, hooks_builder: &mut HooksBuilder, ctx: &mut TxContext): Admin {
    assert!(pool.addy() == hooks_builder.pool_address_(), EHooksBuilderPoolMismatch);

    hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), BlocklistHook {});
    hooks_builder.add_rule(interest_pool::start_add_liquidity_name().utf8(), BlocklistHook {});
    hooks_builder.add_rule_config(BlocklistHook {}, Blocklist { inner: table::new(ctx) });

    admin::new(pool.addy(), ctx)
  }

  public fun approve(pool: &InterestPool<Volatile>, request: &mut Request, ctx: &mut TxContext) {
    assert!(request.pool_address() == pool.addy(), EInvalidRequestPool);
    assert!(
      request.name() == interest_pool::start_swap_name().utf8()
      || request.name() == interest_pool::start_add_liquidity_name().utf8(), 
      EInvalidRequestName
    );

    let blocklist = pool.config<Volatile, BlocklistHook, Blocklist>();

    assert!(!blocklist.inner.contains(ctx.sender()), EBlocklisted);

    request.approve(BlocklistHook {});
  }

  // === Public-View Functions ===

  public fun is_blocklisted(pool: &InterestPool<Volatile>, user: address): bool {
    pool.config<Volatile, BlocklistHook, Blocklist>().inner.contains(user)
  }

  // === Admin Functions ===

  public fun add_blocklist(admin: &Admin, pool: &mut InterestPool<Volatile>, user: address) {
    admin.assert_pool(pool.addy());
    
    let blocklist = pool.config_mut<Volatile, BlocklistHook, Blocklist>(BlocklistHook {});

    blocklist.inner.add(user, true);
  }

  public fun remove_blocklist(admin: &Admin, pool: &mut InterestPool<Volatile>, user: address) {
    admin.assert_pool(pool.addy());
    
    let blocklist = pool.config_mut<Volatile, BlocklistHook, Blocklist>(BlocklistHook {});

    blocklist.inner.remove(user);
  }

  // === Public-Package Functions ===

  // === Private Functions ===

  // === Test Functions === 
}