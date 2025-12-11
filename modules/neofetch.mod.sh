MOD_ID="neofetch"
MOD_NAME="Neofetch"
MOD_DESC="A command-line system information tool."
MOD_GROUP="CLI Tools"

mod_check() {
  command -v neofetch >/dev/null 2>&1
}

mod_install() {
  # APT handles updates automatically during install if new version is available in repo
  ensure_pkg "neofetch"
}

mod_uninstall() {
  log_info "Uninstalling Neofetch..."
  log_cmd "Purging neofetch" sudo apt-get purge -y neofetch
  log_cmd "Autoremoving" sudo apt-get autoremove -y
}

register_module
