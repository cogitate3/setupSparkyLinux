MOD_ID="rclone"
MOD_NAME="Cloud Storage (rclone)"
MOD_DESC="Rsync for cloud storage (Supports Google Drive, Dropbox, OneDrive, etc.)."
MOD_GROUP="Network & Storage"

mod_check() {
  command -v rclone >/dev/null 2>&1
}

mod_status() {
  local v_local=$(rclone version 2>/dev/null | head -n1 | awk '{print $2}' | sed 's/^v//')
  [ -z "$v_local" ] && v_local="unknown"
  
  local v_remote_tag=$(gh_get_latest_tag "rclone/rclone")
  local v_remote="${v_remote_tag#v}"
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  # Legacy script prefers rclone.org install script for the latest version.
  log_info "Installing latest rclone from official script..."
  curl -fsSL https://rclone.org/install.sh < /dev/null | sudo bash

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
  sudo apt-get purge -y rclone < /dev/null
  log_warn "Rclone config (~/.config/rclone/rclone.conf) is preserved."
}

register_module
