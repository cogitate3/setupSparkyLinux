MOD_ID="rclone"
MOD_NAME="Cloud Storage (rclone)"
MOD_DESC="Rsync for cloud storage (Supports Google Drive, Dropbox, OneDrive, etc.)."
MOD_GROUP="Network & Storage"

mod_check() {
  check_pkg_installed "rclone"
}

mod_install() {
  # rclone in Debian repos can be old.
  # But for stability/simplicity in this script context, let's prefer apt unless user wants latest.
  # Start with apt.
  ensure_pkg "rclone"

  if [ "${DRY_RUN:-0}" -ne 1 ]; then
    echo ""
    log_info "Rclone installed."
    print_cyan "--- Rclone Configuration ---"
    read -p "Do you want to run 'rclone config' now to set up a remote? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rclone config
    else
      log_info "You can run 'rclone config' later."
    fi
  fi
}

mod_uninstall() {
  log_info "Uninstalling rclone..."
  sudo apt-get purge -y rclone
  log_warn "Rclone config (~/.config/rclone/rclone.conf) is preserved."
}

register_module
