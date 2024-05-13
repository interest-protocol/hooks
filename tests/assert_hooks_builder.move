#[test_only]
module hooks::assert_hooks_builder {
 use std::string;
 use std::type_name;

 use sui::test_utils::assert_eq;

 use clamm::interest_pool::{Self, HooksBuilder};

 use fun string::utf8 as vector.utf8;

 public fun start_swap<Witness: drop>(self: &mut HooksBuilder): &mut HooksBuilder {
  assert_eq(self.rules().get(&interest_pool::start_swap_name().utf8()).contains(&type_name::get<Witness>()), true);
  self
 }

 public fun finish_swap<Witness: drop>(self: &mut HooksBuilder): &mut HooksBuilder {
  assert_eq(self.rules().get(&interest_pool::finish_swap_name().utf8()).contains(&type_name::get<Witness>()), true);
  self
 }

 public fun start_add_liquidity<Witness: drop>(self: &mut HooksBuilder): &mut HooksBuilder {
  assert_eq(self.rules().get(&interest_pool::start_add_liquidity_name().utf8()).contains(&type_name::get<Witness>()), true);
  self
 }  

 public fun finish_add_liquidity<Witness: drop>(self: &mut HooksBuilder): &mut HooksBuilder {
  assert_eq(self.rules().get(&interest_pool::finish_add_liquidity_name().utf8()).contains(&type_name::get<Witness>()), true);
  self
 }   

 public fun start_remove_liquidity<Witness: drop>(self: &mut HooksBuilder): &mut HooksBuilder {
  assert_eq(self.rules().get(&interest_pool::start_remove_liquidity_name().utf8()).contains(&type_name::get<Witness>()), true);
  self
 } 

 public fun finish_remove_liquidity<Witness: drop>(self: &mut HooksBuilder): &mut HooksBuilder {
  assert_eq(self.rules().get(&interest_pool::finish_remove_liquidity_name().utf8()).contains(&type_name::get<Witness>()), true);
  self
 } 

 public fun start_donate<Witness: drop>(self: &mut HooksBuilder): &mut HooksBuilder {
  assert_eq(self.rules().get(&interest_pool::start_donate_name().utf8()).contains(&type_name::get<Witness>()), true);
  self
 }  

 public fun finish_donate<Witness: drop>(self: &mut HooksBuilder): &mut HooksBuilder {
  assert_eq(self.rules().get(&interest_pool::finish_donate_name().utf8()).contains(&type_name::get<Witness>()), true);
  self
 }
   
}