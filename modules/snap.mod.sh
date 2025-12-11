MOD_ID="snap"
MOD_NAME="Snap Package Manager"
MOD_DESC="Installs Snapd and Snap Store."
MOD_GROUP="System"

mod_check() {
  if command -v snap >/dev/null 2>&1; then
      return 0
  fi
  return 1
}

mod_install() {
  # 1. Install snapd
  ensure_pkg "snapd"

  # 2. Enable service (if systemd)
  if command -v systemctl >/dev/null 2>&1; then
      log_cmd "Enabling snapd.socket" sudo systemctl enable --now snapd.socket
      # Optional: wait not supported directly, but let's assume it works or systemd handles it.
  fi

  # 3. Install Snap Store
  # Snap commands need to run as root usually for install
  if ! snap list 2>/dev/null | grep -q "snap-store"; then
    log_cmd "Installing Snap Store" sudo snap install snap-store
  else
    log_info "Snap Store is already installed."
  fi
}

register_module
