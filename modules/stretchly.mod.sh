MOD_ID="stretchly"
MOD_NAME="Stretchly"
MOD_DESC="A break time reminder app."
MOD_GROUP="Desktop Apps"

mod_check() {
  if check_pkg_installed "stretchly"; then return 0; fi
  if command -v stretchly >/dev/null 2>&1; then return 0; fi
  return 1
}

mod_install() {
  local repo="hovancik/stretchly"
  log_info "Finding latest .deb for $repo..."
  
  local url
  url=$(gh_pick_asset "$repo" "deb")
  
  if [ -z "$url" ]; then
    log_err "Could not find .deb asset for $repo"
    return 1
  fi
  
  local tmp_deb="/tmp/stretchly_install.deb"
  log_cmd "Downloading Stretchly" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  
  rm -f "$tmp_deb"
}

register_module
