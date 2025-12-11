MOD_ID="krusader"
MOD_NAME="Krusader"
MOD_DESC="Advanced twin-panel file manager (KDE)."
MOD_GROUP="System"

mod_check() {
  command -v krusader >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "krusader"
}

mod_uninstall() {
  log_info "Uninstalling Krusader..."
  log_cmd "Purging krusader" sudo apt-get purge -y krusader
}

register_module
