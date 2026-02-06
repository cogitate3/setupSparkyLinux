#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/log.sh"
. "$SCRIPT_DIR/lib/cmd.sh"
. "$SCRIPT_DIR/lib/gh.sh"
. "$SCRIPT_DIR/lib/menu.sh"

: "${DRY_RUN:=0}"

declare -A M_NAME M_GROUP M_DESC M_TAGS
declare -A M_FILE
declare -A M_HAS_CHECK M_HAS_INSTALL M_HAS_UNINSTALL M_HAS_STATUS
declare -A M_DEPS_CMDS M_DEPS_PKGS M_REQUIRES
MODULE_IDS=()

declare -a RES_NAME RES_ACTION RES_STATUS

register_module() {
  local id="${MOD_ID:?MOD_ID required}"
  
  # Prevent duplicates if module is re-sourced
  if [ -n "${M_FILE[$id]-}" ]; then
     return 0
  fi

  MODULE_IDS+=("$id")
  M_NAME["$id"]="${MOD_NAME:-$id}"
  M_GROUP["$id"]="${MOD_GROUP:-Misc}"
  M_DESC["$id"]="${MOD_DESC:-}"
  M_TAGS["$id"]="${MOD_TAGS:-}"
  M_FILE["$id"]="${BASH_SOURCE[1]}"

  M_HAS_CHECK["$id"]=$(declare -F mod_check     >/dev/null && echo 1 || echo 0)
  M_HAS_INSTALL["$id"]=$(declare -F mod_install   >/dev/null && echo 1 || echo 0)
  M_HAS_UNINSTALL["$id"]=$(declare -F mod_uninstall>/dev/null && echo 1 || echo 0)
  M_HAS_STATUS["$id"]=$(declare -F mod_status    >/dev/null && echo 1 || echo 0)

  M_DEPS_CMDS["$id"]="${MOD_DEPS_CMDS[*]-}"
  M_DEPS_PKGS["$id"]="${MOD_DEPS_PKGS[*]-}"
  M_REQUIRES["$id"]="${MOD_REQUIRES[*]-}"
}


discover_modules() {
  shopt -s nullglob
  for f in "$SCRIPT_DIR/modules/"*.mod.sh; do . "$f"; done
}

ensure_deps_for() {
  local id="$1"
  for c in ${M_DEPS_CMDS[$id]:-}; do ensure_cmd "$c"; done
  for p in ${M_DEPS_PKGS[$id]:-};  do ensure_pkg "$p"; done
}

run_module() {  # $1=id  $2=action
  local id="$1" action="${2:-install}"
  # Run in subshell with Strict Error Checking enabled
  # This ensures any failed command inside the module triggers a failure status
  (
    set -e
    . "${M_FILE[$id]}"
    ensure_deps_for "$id"
    case "$action" in
      check)
        if [ "${M_HAS_CHECK[$id]}" = "1" ]; then mod_check; else log_warn "$id 无 check"; fi ;;
      status)
        if [ "${M_HAS_STATUS[$id]}" = "1" ]; then mod_status; else log_warn "$id 无 status"; fi ;;
      install)
        if [ "${M_HAS_INSTALL[$id]}" = "1" ]; then mod_install; else log_err "$id 不支持安装"; return 2; fi ;;
      uninstall)
        if [ "${M_HAS_UNINSTALL[$id]}" = "1" ]; then mod_uninstall; else log_err "$id 不支持卸载"; return 2; fi ;;
      *) log_err "未知动作：$action"; return 2 ;;
    esac
  )
}

by_group() { local g="$1"; for id in "${MODULE_IDS[@]}"; do [[ "${M_GROUP[$id]}" == "$g" ]] && echo "$id"; done; }
by_tag()   { local t="$1"; for id in "${MODULE_IDS[@]}"; do [[ ",${M_TAGS[$id]}," == *",$t,"* ]] && echo "$id"; done; }

usage() {
cat <<'EOF'
SparkyLinux Modular Setup Script

Usage: sudo ./setup.sh [OPTIONS]

Common Actions:
  ./setup.sh                    # Open the Interactive Menu (Default)
  ./setup.sh --list             # List all available modules
  ./setup.sh --help             # Show this help message

Advanced Commands:
  # Install specific modules (comma separated)
  ./setup.sh --run zsh,fonts,rclone

  # Check status of specific modules
  ./setup.sh --run davfs2,pot --action check

  # Uninstall modules by specific tag
  ./setup.sh --tags desktop --action uninstall

  # Install a whole group of modules (Dry Run)
  ./setup.sh --group "Dev Tools" --dry-run 1

Options:
  --run <ids>     Modules to run (e.g. "vim,git")
  --group <name>  Run all modules in a group (e.g. "System")
  --tags <tags>   Run all modules with specific tags
  --action <act>  Action to perform: install (default), uninstall, check, status
  --dry-run 1     Simulate actions without making changes
  --menu          Force open the interactive menu
  --list          List all modules organized by group

Examples:
  sudo ./setup.sh --run rclone
  sudo ./setup.sh --run pot --action install
EOF
}

ACTION="install"; RUN_IDS=""; TAGS=""; GROUP=""; MENU=0
while [ $# -gt 0 ]; do
  case "$1" in
    --action) shift; ACTION="$1" ;;
    --run)    shift; RUN_IDS="$1" ;;
    --tags)   shift; TAGS="$1" ;;
    --group)  shift; GROUP="$1" ;;
    --dry-run)shift; DRY_RUN="$1" ;;
    --list)   LIST=1 ;;
    --menu)   MENU=1 ;;
    -h|--help)usage; exit 0 ;;
    *) log_warn "忽略未知参数：$1" ;;
  esac
  shift
done

# Default to Interactive Menu if no targets specified
if [ -z "$RUN_IDS" ] && [ -z "$TAGS" ] && [ -z "$GROUP" ] && [ "${LIST:-0}" != "1" ]; then
  MENU=1
fi

main() {
  discover_modules

  if [ "${LIST:-0}" = 1 ]; then
    declare -A seen
    for id in "${MODULE_IDS[@]}"; do g="${M_GROUP[$id]}"; seen["$g"]=1; done
    for g in "${!seen[@]}"; do
      echo "== $g =="
      for id in $(by_group "$g"); do
        printf " - %-18s  %s\n" "$id" "${M_NAME[$id]}"
      done
      echo
    done
    exit 0
  fi

  if [ "$MENU" = 1 ]; then
    # Disable strict error checking for the interactive loop to prevent crashes
    set +eu
    while true; do
      draw_main_menu
      
      read -p "Enter option(s): " choice_str
      # Convert input string to array (space separated)
      read -ra choices <<< "$choice_str"
      
      [[ "$choice_str" == "0" || "$choice_str" == "q" ]] && exit 0
      
      # Reset Global Arrays for Results
      RES_NAME=()
      RES_ACTION=()
      RES_STATUS=()
      count=0

      # Handle Batch Actions (All)
      if [[ "${choices[0]}" =~ ^[Aa]$ ]]; then
          echo "Installing ALL modules..."
          for id in "${MODULE_IDS[@]}"; do
              log_info "==> ${M_NAME[$id]} [install]"
              run_module "$id" "install"
              st=$?
              RES_NAME+=("${M_NAME[$id]}")
              RES_ACTION+=("install")
              RES_STATUS+=($st)
              ((count++))
          done
          draw_summary $count
          read -p "Press Enter to continue..."
          continue
      fi
      
      if [[ "${choices[0]}" =~ ^[Uu]$ ]]; then
          echo "Uninstalling ALL modules..."
          for id in "${MODULE_IDS[@]}"; do 
              log_info "==> ${M_NAME[$id]} [uninstall]"
              run_module "$id" "uninstall"
              st=$?
              RES_NAME+=("${M_NAME[$id]}")
              RES_ACTION+=("uninstall")
              RES_STATUS+=($st)
              ((count++))
          done
          draw_summary $count
          read -p "Press Enter to continue..."
          continue
      fi

      # Handle Numeric Inputs Loop
      for choice in "${choices[@]}"; do
          if [[ "$choice" =~ ^[0-9]+$ ]]; then
              action="install"
              idx=$((10#$choice))
              
              if [ $idx -gt 100 ]; then
                  action="uninstall"
                  idx=$((idx - 100))
              fi
              
              id="${MOD_INDEX_MAP[$idx]}"
              
              if [ -n "$id" ]; then
                  echo ""
                  log_info "Selected: ${M_NAME[$id]} ($id) [$action]"
                  
                  # Legacy Logic: Check if already installed
                  if [ "$action" = "install" ] && [ "${M_HAS_CHECK[$id]}" = "1" ]; then
                      if run_module "$id" "check" >/dev/null 2>&1; then
                          # Already installed. Check for update?
                          local needs_prompt=1
                          local v_msg=""
                          if [ "${M_HAS_STATUS[$id]}" = "1" ]; then
                              # mod_status return codes: 0=latest, 1=update avail, 2=not inst
                              # It should now echo "local|remote"
                              set +e
                              local v_info; v_info=$(run_module "$id" "status")
                              local status_ret=$?
                              set -e
                              
                              local v_l="${v_info%|*}"
                              local v_r="${v_info#*|}"

                              if [ $status_ret -eq 1 ]; then
                                  printf "\033[1;36m[%s] [INFO] %s 发现新版本！[当前: %s, 最新: %s]。是否执行更新？[Y/n]: \033[0m" "$(date +'%F %T')" "${M_NAME[$id]}" "${v_l:-未知}" "${v_r:-未知}"
                                  read -r confirm
                                  if [[ "$confirm" =~ ^[Nn]$ ]]; then
                                      log_info "跳过 ${M_NAME[$id]} 的更新。"
                                      continue
                                  fi
                                  needs_prompt=0
                              elif [ $status_ret -eq 0 ]; then
                                  v_msg=" [本地版本: ${v_l:-未知}, 最新版本: ${v_r:-未知}]"
                              fi
                          fi

                          if [ $needs_prompt -eq 1 ]; then
                              printf "\033[1;33m[%s] [WARN] %s%s 已经安装最新版本，是否重新安装？[y/N]: \033[0m" "$(date +'%F %T')" "${M_NAME[$id]}" "$v_msg"
                              read -r confirm
                              if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                                  log_info "用户取消重新安装 ${M_NAME[$id]}，返回主菜单。"
                                  continue
                              fi
                              log_info "确认重新安装 ${M_NAME[$id]}..."
                              export FORCE_REINSTALL=1
                          fi
                      fi
                  fi

                  # log debug removed
                  run_module "$id" "$action"
                  st=$?
                  # Reset force flag
                  unset FORCE_REINSTALL
                  
                  # Record Result
                  RES_NAME+=("${M_NAME[$id]}")
                  RES_ACTION+=("$action")
                  RES_STATUS+=($st)
                  
                  count=$((count + 1))
              else
                  log_warn "Invalid selection: $choice"
              fi
          else
              log_warn "Ignored invalid input: $choice"
          fi
      done
      
      # Show Summary if any tasks ran
      if [ $count -gt 0 ]; then
          draw_summary $count
      fi
      
      echo ""
      read -p "Press Enter to continue..." || true
    done
    exit 0
  fi

  SEL=()
if [ -n "$RUN_IDS" ]; then
  IFS=',' read -r -a tmp <<<"$RUN_IDS"
  SEL+=("${tmp[@]}")
fi

  if [ -n "$TAGS" ]; then IFS=',' read -r -a ts <<<"$TAGS"
    for t in "${ts[@]}"; do while read -r id; do SEL+=("$id"); done < <(by_tag "$t"); done
  fi
  if [ -n "$GROUP" ]; then while read -r id; do SEL+=("$id"); done < <(by_group "$GROUP"); fi
  if (( ${#SEL[@]} == 0 )); then
    # Should not happen if MENU=1 handles the default case, but safety check:
    log_warn "No modules selected to run."
    exit 0
  fi

  for id in "${SEL[@]}"; do
    log_info "==> ${M_NAME[$id]} [${ACTION}]"
    run_module "$id" "$ACTION"
  done
}
main "$@"
