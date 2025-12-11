MOD_ID="pot"
MOD_NAME="Pot Desktop"
MOD_DESC="A cross-platform translator application."
MOD_GROUP="Desktop Apps"

mod_check() {
  command -v pot >/dev/null 2>&1
}

mod_install() {
  # 1. Dependencies
  ensure_pkg "xapp" "libxapp1" "libxapp-gtk3-module" "curl"

  # 2. Download and Install
  local repo="pot-app/pot-desktop"
  log_info "Finding latest .deb for $repo..."
  
  local url
  url=$(gh_pick_asset "$repo" "deb")
  
  if [ -z "$url" ]; then
    log_err "Could not find .deb asset for $repo"
    return 1
  fi
  
  local tmp_deb="/tmp/pot_install.deb"
  log_cmd "Downloading Pot Desktop" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  
  rm -f "$tmp_deb"
}

register_module
