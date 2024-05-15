module hooks::admin {
  // === Imports ===

  // === Errors ===

  const EInvalidPoolAddress: u64 = 0;

  // === Constants ===

  // === Structs ===

  public struct Admin has key, store {
   id: UID,
   pool: address
  }

  // === Method Aliases ===

  // === Public-Mutative Functions ===

  // === Public-View Functions ===

  public fun addy(self: &Admin): address {
   self.id.to_address()
  }

  public fun pool(self: &Admin): address {
   self.pool
  }

  public fun assert_pool(self: &Admin, pool: address) {
    assert!(self.pool == pool, EInvalidPoolAddress);
  }

  // === Admin Functions ===

  public fun destroy(admin: Admin) {
    let Admin { id, pool: _ } = admin;

    id.delete();
  }

  // === Public-Package Functions ===

  public(package) fun new(pool: address, ctx: &mut TxContext): Admin {
   Admin {
    id: object::new(ctx),
    pool
   }
  }

  // === Private Functions ===

  // === Test Functions === 

  #[test_only]
  public fun new_for_testing(pool: address, ctx: &mut TxContext): Admin {
    new(pool, ctx)
  }
}