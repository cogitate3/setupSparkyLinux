MOD_ID="localsend"
MOD_NAME="LocalSend"
MOD_DESC="Share files to nearby devices."
MOD_GROUP="Desktop Apps"

mod_check() {
  if check_pkg_installed "localsend"; then return 0; fi
  return 1
}

mod_install() {
  local repo="localsend/localsend"
  log_info "Finding latest .deb for $repo..."
  
  local url
  url=$(gh_pick_asset "$repo" "deb")
  
  if [ -z "$url" ]; then
    log_err "Could not find .deb asset for $repo"
    return 1
  fi
  
  local tmp_deb="/tmp/localsend_install.deb"
  log_cmd "Downloading LocalSend" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  
  rm -f "$tmp_deb"
}

register_module
