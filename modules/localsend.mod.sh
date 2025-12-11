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
  
  if mod_check; then
    local v_local
    v_local=$(dpkg -l | grep "^ii\s*localsend" | awk '{print $3}')
    local v_remote_tag
    v_remote_tag=$(gh_get_latest_tag "$repo")
    local v_remote="${v_remote_tag#v}"
    
    if [[ "$v_local" == *"$v_remote"* ]]; then
      log_info "LocalSend is up to date ($v_local). Skipping."
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
  
  local tmp_deb="/tmp/localsend_install.deb"
  log_cmd "Downloading LocalSend" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  rm -f "$tmp_deb"
}

mod_uninstall() {
  log_info "Uninstalling LocalSend..."
  log_cmd "Purging localsend" sudo apt-get purge -y localsend
}

register_module
