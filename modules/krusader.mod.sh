MOD_ID="krusader"
MOD_NAME="Krusader"
MOD_DESC="Advanced twin-panel file manager (KDE)."
MOD_GROUP="System"

mod_check() {
  command -v krusader >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "krusader")
  local v_remote=$(apt-cache policy "krusader" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "krusader"
}

mod_uninstall() {
  log_info "Uninstalling Krusader..."
  log_cmd "Purging krusader" sudo apt-get purge -y krusader < /dev/null
}

register_module
