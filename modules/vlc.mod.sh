MOD_ID="vlc"
MOD_NAME="VLC Media Player"
MOD_DESC="The versatile media player."
MOD_GROUP="Multimedia"

mod_check() {
  command -v vlc >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "vlc"
}

mod_uninstall() {
  log_info "Uninstalling VLC..."
  log_cmd "Purging vlc" sudo apt-get purge -y vlc
}

register_module
