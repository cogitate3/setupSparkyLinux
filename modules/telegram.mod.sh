MOD_ID="telegram"
MOD_NAME="Telegram"
MOD_DESC="Official Telegram Desktop messaging app."
MOD_GROUP="System"

mod_check() {
  command -v telegram-desktop >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "telegram-desktop"
}

mod_uninstall() {
  log_info "Uninstalling Telegram..."
  log_cmd "Purging telegram-desktop" sudo apt-get purge -y telegram-desktop
}

register_module
