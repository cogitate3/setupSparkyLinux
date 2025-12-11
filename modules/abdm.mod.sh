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
  
  if mod_check; then
    local v_local
    v_local=$(dpkg -l | grep "^ii\s*abdownloadmanager" | awk '{print $3}')
    local v_remote_tag
    v_remote_tag=$(gh_get_latest_tag "$repo")
    local v_remote="${v_remote_tag#v}"
    
    if [[ "$v_local" == *"$v_remote"* ]]; then
      log_info "ABDM is up to date ($v_local). Skipping."
      return 0
    fi
     log_info "New version available: Local=$v_local, Remote=$v_remote. Updating..."
  fi

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

mod_uninstall() {
  log_info "Uninstalling AB Download Manager..."
  log_cmd "Purging abdownloadmanager" sudo apt-get purge -y abdownloadmanager
}

register_module
