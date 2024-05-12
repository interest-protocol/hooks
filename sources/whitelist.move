module hooks::whitelist {
  // === Imports ===
  use std::string;
  
  use sui::table::{Self, Table};

  use clamm::curves::Volatile;
  use clamm::interest_pool::{Self, InterestPool, HooksBuilder, Request};

  // === Errors ===

  const EHooksBuilderPoolMismatch: u64 = 0;
  const EInvalidRequestName: u64 = 1;
  const ENotWhitelisted: u64 = 2;
  const EInvalidRequestPool: u64 = 3;
  const EInvalidAdmin: u64 = 4;

  // === Constants ===

  // === Structs ===

  public struct WhitelistHook has drop {}

  public struct Whitelist has store {
    inner: Table<address, bool>
  }

  public struct Admin has key, store {
   id: UID,
   pool: address
  }

  // === Method Aliases ===

  use fun string::utf8 as vector.utf8;

  // === Public-Mutative Functions ===

  public fun add(pool: &InterestPool<Volatile>, hooks_builder: &mut HooksBuilder, ctx: &mut TxContext): Admin {
    assert!(pool.addy() == hooks_builder.pool_address_(), EHooksBuilderPoolMismatch);

    hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), WhitelistHook {});
    hooks_builder.add_rule(interest_pool::start_add_liquidity_name().utf8(), WhitelistHook {});
    hooks_builder.add_rule_config(WhitelistHook {}, Whitelist { inner: table::new(ctx) });

    Admin {
      id: object::new(ctx),
      pool: pool.addy()
    }
  }

  public fun approve(pool: &InterestPool<Volatile>, request: &mut Request, ctx: &mut TxContext) {
    assert!(request.pool_address() == pool.addy(), EInvalidRequestPool);
    assert!(
      request.name() == interest_pool::start_swap_name().utf8()
      || request.name() == interest_pool::start_add_liquidity_name().utf8(), 
      EInvalidRequestName
    );

    let whitelist = pool.config<Volatile, WhitelistHook, Whitelist>();

    assert!(whitelist.inner.contains(ctx.sender()), ENotWhitelisted);

    request.approve(WhitelistHook {});
  }

  // === Public-View Functions ===

  public fun is_whitelisted(pool: &InterestPool<Volatile>, user: address): bool {
    pool.config<Volatile, WhitelistHook, Whitelist>().inner.contains(user)
  }

  // === Admin Functions ===

  public fun add_whitelist(admin: &Admin, pool: &mut InterestPool<Volatile>, user: address) {
    assert!(admin.id.to_address() == pool.addy(), EInvalidAdmin);
    
    let whitelist = pool.config_mut<Volatile, WhitelistHook, Whitelist>(WhitelistHook {});

    whitelist.inner.add(user, true);
  }

  public fun remove_whitelist(admin: &Admin, pool: &mut InterestPool<Volatile>, user: address) {
    assert!(admin.id.to_address() == pool.addy(), EInvalidAdmin);
    
    let whitelist = pool.config_mut<Volatile, WhitelistHook, Whitelist>(WhitelistHook {});

    whitelist.inner.remove(user);
  }

  public fun destroy(admin: Admin) {
    let Admin { id, pool: _ } = admin;

    id.delete();
  }

  // === Public-Package Functions ===

  // === Private Functions ===

  // === Test Functions === 
}