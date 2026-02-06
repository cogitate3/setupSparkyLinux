MOD_ID="neofetch"
MOD_NAME="Neofetch"
MOD_DESC="A command-line system information tool."
MOD_GROUP="CLI Tools"

mod_check() {
  command -v fastfetch >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "fastfetch")
  local v_remote=$(apt-cache policy "fastfetch" 2>/dev/null | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "fastfetch"
  # Create a compatibility alias if neofetch is typed
  if ! command -v neofetch >/dev/null 2>&1; then
      log_cmd "Creating neofetch alias" sudo ln -sf /usr/bin/fastfetch /usr/bin/neofetch
  fi
}

mod_uninstall() {
  log_info "Uninstalling Fastfetch..."
  log_cmd "Purging fastfetch" sudo apt-get purge -y fastfetch < /dev/null
  if [ -L /usr/bin/neofetch ]; then
      sudo rm /usr/bin/neofetch
  fi
}

register_module
