MOD_ID="snap"
MOD_NAME="Snap Package Manager"
MOD_DESC="Snapd and Snap Store."
MOD_GROUP="System"

mod_check() {
  command -v snap >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "snapd"
  log_cmd "Installing snap-store" sudo snap install snap-store
}

mod_uninstall() {
  log_info "Uninstalling Snap..."
  sudo snap remove snap-store
  sudo apt-get purge -y snapd
}

register_module
