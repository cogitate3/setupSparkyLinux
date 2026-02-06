MOD_ID="snap"
MOD_NAME="Snap Package Manager"
MOD_DESC="Snapd and Snap Store."
MOD_GROUP="System"

mod_check() {
  command -v snap >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "snapd")
  local v_remote=$(apt-cache policy "snapd" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "snapd"
  log_cmd "Installing snap-store" sudo snap install snap-store
}

mod_uninstall() {
  log_info "Uninstalling Snap..."
  sudo snap remove snap-store
  sudo apt-get purge -y snapd < /dev/null
}

register_module
