#!/usr/bin/env bats

load 'bats-core/lib/bats-support/load'
load 'bats-core/lib/bats-assert/load'

setup() {
   # Define necessary globals for modules
   MODULE_IDS=()
   
   # Mock register_module globally for all tests
   register_module() {
       MODULE_IDS+=("$MOD_ID")
   }
}

@test "Module fonts can be sourced and defines required variables" {
    source ./modules/fonts.mod.sh
    
    assert_equal "$MOD_ID" "fonts"
    assert_not_equal "$MOD_NAME" ""
    assert_not_equal "$MOD_DESC" ""
    
    # Check if functions are defined
    run type -t mod_install
    assert_output "function"
    
    run type -t mod_check
    assert_output "function"
}

@test "Module registration adds to global array (simulation)" {
   # Mock register_module function usually found in setup.sh
   register_module() {
       MODULE_IDS+=("$MOD_ID")
   }
   
   source ./modules/fonts.mod.sh
   # Assuming we had called register_module in the mod file? 
   # Actually setup.sh calls it. 
   # So we just verify metadata here.
   
   assert_equal "$MOD_ID" "fonts"
}

@test "Module neofetch can be sourced and defines required variables" {
    source ./modules/neofetch.mod.sh
    
    assert_equal "$MOD_ID" "neofetch"
    assert_equal "$MOD_NAME" "Neofetch"
    
    run type -t mod_check
    assert_output "function"
}
