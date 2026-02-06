#!/bin/bash
export BATS_LIB_PATH="$PWD/tests/bats-core/lib"
"$PWD/tests/bats-core/bin/bats" "$@"
