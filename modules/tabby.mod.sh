MOD_ID="tabby"
MOD_NAME="Tabby Terminal"
MOD_DESC="A highly configurable terminal emulator."
MOD_GROUP="Dev Tools"

mod_check() {
  if check_pkg_installed "tabby"; then return 0; fi
  return 1
}

mod_install() {
  local repo="Eugeny/tabby"
  log_info "Finding latest .deb for $repo..."
  
  local url
  url=$(gh_pick_asset "$repo" "deb")
  
  if [ -z "$url" ]; then
    log_err "Could not find .deb asset for $repo"
    return 1
  fi
  
  local tmp_deb="/tmp/tabby_install.deb"
  log_cmd "Downloading Tabby" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  
  rm -f "$tmp_deb"
}

register_module
