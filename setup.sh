#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/log.sh"
. "$SCRIPT_DIR/lib/cmd.sh"
. "$SCRIPT_DIR/lib/gh.sh"

: "${DRY_RUN:=0}"

declare -A M_NAME M_GROUP M_DESC M_TAGS
declare -A M_FILE
declare -A M_HAS_CHECK M_HAS_INSTALL M_HAS_UNINSTALL M_HAS_STATUS
declare -A M_DEPS_CMDS M_DEPS_PKGS M_REQUIRES
MODULE_IDS=()

register_module() {
  local id="${MOD_ID:?MOD_ID required}"
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
  . "${M_FILE[$id]}"
  ensure_deps_for "$id"
  case "$action" in
    check)     [ "${M_HAS_CHECK[$id]}"    = 1 ] && mod_check    || { log_warn "$id 无 check"; return 0; } ;;
    status)    [ "${M_HAS_STATUS[$id]}"   = 1 ] && mod_status   || { log_warn "$id 无 status"; return 0; } ;;
    install)   [ "${M_HAS_INSTALL[$id]}"  = 1 ] && mod_install  || { log_err  "$id 不支持安装"; return 2; } ;;
    uninstall) [ "${M_HAS_UNINSTALL[$id]}"= 1 ] && mod_uninstall|| { log_err  "$id 不支持卸载"; return 2; } ;;
    *) log_err "未知动作：$action"; return 2 ;;
  esac
}

by_group() { local g="$1"; for id in "${MODULE_IDS[@]}"; do [[ "${M_GROUP[$id]}" == "$g" ]] && echo "$id"; done; }
by_tag()   { local t="$1"; for id in "${MODULE_IDS[@]}"; do [[ ",${M_TAGS[$id]}," == *",$t,"* ]] && echo "$id"; done; }

usage() {
cat <<'EOF'
Usage:
  ./setup.sh --list
  ./setup.sh --menu
  ./setup.sh --run fonts,zsh --action install
  ./setup.sh --tags desktop --action uninstall
  ./setup.sh --group "Storage & Mount" --dry-run 1
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
    PS3="请选择（数字，q退出）> "
    select choice in $(printf "%s\n" "${MODULE_IDS[@]}" "Quit"); do
      [[ "$REPLY" == "q" || "$choice" == "Quit" ]] && exit 0
      [ -n "$choice" ] || continue
      id="$choice"
      echo "# ${M_NAME[$id]} — ${M_DESC[$id]}"
      run_module "$id" "$ACTION"
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
    SEL=("${MODULE_IDS[@]}")
  fi

  for id in "${SEL[@]}"; do
    log_info "==> ${M_NAME[$id]} [${ACTION}]"
    run_module "$id" "$ACTION"
  done
}
main "$@"
