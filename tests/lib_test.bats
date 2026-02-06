#!/usr/bin/env bats

load 'bats-core/lib/bats-support/load'
load 'bats-core/lib/bats-assert/load'

setup() {
    # Mocking environment
    source ./lib/log.sh
    source ./lib/cmd.sh
    LOG_FILE="/dev/null"
}

@test "detect_installer returns a valid package manager or unknown" {
    run detect_installer
    assert_output --regexp '^(apt|dnf|pacman|zypper|unknown)$'
}

@test "has_cmd returns 0 for existing command" {
    run has_cmd "bash"
    assert_success
}

@test "has_cmd returns 1 for non-existing command" {
    run has_cmd "nonexistentcommandsurely"
    assert_failure
}

@test "version_ge compares versions correctly" {
    run version_ge "1.2.0" "1.1.0"
    assert_success
    
    run version_ge "1.0.0" "1.0.0"
    assert_success

    run version_ge "0.9.9" "1.0.0"
    assert_failure
}
