MOD_ID="spacefm"
MOD_NAME="SpaceFM"
MOD_DESC="A multi-panel tabbed file manager."
MOD_GROUP="System"

mod_check() {
  command -v spacefm >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "spacefm")
  local v_remote=$(apt-cache policy "spacefm" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "spacefm"
}

mod_uninstall() {
  log_info "Uninstalling SpaceFM..."
  log_cmd "Purging spacefm" sudo apt-get purge -y spacefm < /dev/null
}

register_module
