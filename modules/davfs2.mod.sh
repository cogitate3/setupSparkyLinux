MOD_ID="davfs2"
MOD_NAME="WebDAV (davfs2)"
MOD_DESC="Mount WebDAV shares."
MOD_GROUP="Network & Storage"

mod_check() {
  check_pkg_installed "davfs2"
}

mod_install() {
  ensure_pkg "davfs2"
  
  # Permission setup
  local target_user="${SUDO_USER:-$USER}"
  log_info "Adding $target_user to davfs2 group..."
  sudo usermod -aG davfs2 "$target_user"
  sudo chmod u+s /usr/sbin/mount.davfs
}

mod_uninstall() {
  log_info "Uninstalling Davfs2..."
  sudo apt-get purge -y davfs2
}

register_module
