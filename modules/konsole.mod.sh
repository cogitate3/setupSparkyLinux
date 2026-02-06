MOD_ID="konsole"
MOD_NAME="Konsole"
MOD_DESC="KDE Terminal Emulator."
MOD_GROUP="System"

mod_check() {
  command -v konsole >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "konsole")
  local v_remote=$(apt-cache policy "konsole" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "konsole"
}

mod_uninstall() {
  log_info "Uninstalling Konsole..."
  log_cmd "Purging konsole" sudo apt-get purge -y konsole < /dev/null
}

register_module
