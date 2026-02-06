#!/usr/bin/env bash
source lib/log.sh
source lib/cmd.sh
source lib/gh.sh

check_mod() {
  local f="modules/$1.mod.sh"
  source "$f"
  echo "Checking $MOD_NAME ($1)..."
  mod_status
  echo "Return code: $?"
  echo "----------------"
}


for f in modules/*.mod.sh; do
    mod_id=$(basename "$f" .mod.sh)
    (
        check_mod "$mod_id"
    )
done
