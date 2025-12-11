MOD_ID="abdm"
MOD_NAME="AB Download Manager"
MOD_DESC="A modern download manager."
MOD_GROUP="Desktop Apps"

mod_check() {
  if check_pkg_installed "abdownloadmanager"; then return 0; fi
  return 1
}

mod_install() {
  ensure_pkg "wget"

  local repo="amir1376/ab-download-manager"
  log_info "Finding latest .deb for $repo..."
  
  local url
  url=$(gh_pick_asset "$repo" "deb")
  
  if [ -z "$url" ]; then
    log_err "Could not find .deb asset for $repo"
    return 1
  fi
  
  local tmp_deb="/tmp/abdm_install.deb"
  log_cmd "Downloading AB Download Manager" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  
  rm -f "$tmp_deb"
}

register_module
