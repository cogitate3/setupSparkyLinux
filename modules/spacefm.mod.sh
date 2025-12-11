MOD_ID="spacefm"
MOD_NAME="SpaceFM"
MOD_DESC="A multi-panel tabbed file manager."
MOD_GROUP="System"

mod_check() {
  command -v spacefm >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "spacefm"
}

mod_uninstall() {
  log_info "Uninstalling SpaceFM..."
  log_cmd "Purging spacefm" sudo apt-get purge -y spacefm
}

register_module
