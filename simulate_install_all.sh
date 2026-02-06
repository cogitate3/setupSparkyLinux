#!/usr/bin/env bash
set -e
export DRY_RUN=1

# Source libs
source lib/log.sh
source lib/cmd.sh
source lib/gh.sh
source lib/menu.sh

# Common setup variables normally in setup.sh
declare -A M_NAME M_GROUP M_DESC M_TAGS M_FILE
declare -A M_HAS_CHECK M_HAS_INSTALL M_HAS_UNINSTALL M_HAS_STATUS
declare -A M_DEPS_CMDS M_DEPS_PKGS
MODULE_IDS=()

# Mock register_module to populate logic
register_module() {
  local id="${MOD_ID:?MOD_ID required}"
  MODULE_IDS+=("$id")
  M_NAME["$id"]="${MOD_NAME:-$id}"
  M_FILE["$id"]="$f"
  # Has functions? We'll check at runtime or blindly assume yes for simulation
  M_HAS_INSTALL["$id"]=1
}

# Mock sudo for DRY_RUN of direct calls
sudo() {
    echo "DRY-RUN (sudo): $*"
    return 0
}
export -f sudo

# Load all modules
shopt -s nullglob
for f in modules/*.mod.sh; do 
    # Source in subshell to get ID/Name, or just grep it?
    # Better: verify we can source it.
    source "$f"
done

# Mock run_module from setup.sh
run_module() {  # $1=id  $2=action
  local id="$1" action="${2:-install}"
  local f="${M_FILE[$id]}"
  
  # Source again to ensure function definitions are current
  source "$f"
  
  if [ "$action" = "install" ]; then
      log_info "Simulating Install: ${M_NAME[$id]}"
      mod_install
  fi
}

start_ts=$(date +%s)
echo "=== Starting Dry Run: Install All ==="

RES_NAME=()
RES_ACTION=()
RES_STATUS=()
count=0

for id in "${MODULE_IDS[@]}"; do
    echo "------------------------------------------------"
    log_info "==> ${M_NAME[$id]} [install]"
    
    # Run in subshell to protect environment? setup.sh doesn't use subshell for run_module usually, 
    # but isolation is good. However, setup.sh calls it directly.
    # Let's call directly to be accurate to setup.sh bugs.
    
    # Catch errors? setup.sh uses simple call.
    if run_module "$id" "install"; then
        st=0
    else
        st=$?
        log_err "Module failed with $st"
    fi
    
    RES_NAME+=("${M_NAME[$id]}")
    RES_ACTION+=("install")
    RES_STATUS+=($st)
    ((count++))
done

echo "------------------------------------------------"
echo "=== Summary Generation check ==="
draw_summary $count

end_ts=$(date +%s)
echo "Done in $((end_ts - start_ts)) seconds."
