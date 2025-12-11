MOD_ID="sshfs"
MOD_NAME="SSHFS"
MOD_DESC="Filesystem client based on SSH File Transfer Protocol."
MOD_GROUP="Network & Storage"

mod_check() {
  command -v sshfs >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "sshfs"
  
  local target_user="${SUDO_USER:-$USER}"
  log_info "Adding $target_user to fuse group (if exists)..."
  if getent group fuse >/dev/null; then
    sudo usermod -aG fuse "$target_user"
  fi
}

mod_uninstall() {
  log_info "Uninstalling SSHFS..."
  sudo apt-get purge -y sshfs
}

register_module
