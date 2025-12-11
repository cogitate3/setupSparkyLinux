MOD_ID="geany"
MOD_NAME="Geany"
MOD_DESC="A fast and lightweight IDE."
MOD_GROUP="Desktop Apps"

mod_check() {
  command -v geany >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "geany" "geany-plugins" "geany-plugin-markdown"
}

mod_uninstall() {
  log_info "Uninstalling Geany..."
  log_cmd "Purging geany" sudo apt-get purge -y geany geany-plugins geany-plugin-markdown
}

register_module
