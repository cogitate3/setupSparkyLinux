MOD_ID="plank"
MOD_NAME="Plank Dock"
MOD_DESC="Stupidly simple."
MOD_GROUP="Appearance"

mod_check() {
  command -v plank >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "plank"
}

mod_uninstall() {
  log_info "Uninstalling Plank..."
  sudo apt-get purge -y plank
}

register_module
