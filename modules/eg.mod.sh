MOD_ID="eg"
MOD_NAME="Eg (TLDR Client)"
MOD_DESC="Useful examples at the command line."
MOD_GROUP="CLI Tools"

mod_check() {
  command -v eg >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "python3-full" "python3-pip" "pipx"
  
  local target_user="${SUDO_USER:-$USER}"
  log_info "Installing 'eg' via pipx for user $target_user..."
  sudo -u "$target_user" pipx install eg
}

register_module
