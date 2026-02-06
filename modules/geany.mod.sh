MOD_ID="geany"
MOD_NAME="Geany"
MOD_DESC="A fast and lightweight IDE."
MOD_GROUP="Desktop Apps"

mod_check() {
  command -v geany >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "geany")
  local v_remote=$(apt-cache policy "geany" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "geany" "geany-plugins" "geany-plugin-markdown"
}

mod_uninstall() {
  log_info "Uninstalling Geany..."
  log_cmd "Purging geany" sudo apt-get purge -y geany geany-plugins geany-plugin-markdown < /dev/null
}

register_module
