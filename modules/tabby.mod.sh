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
  
  if mod_check; then
    local v_local
    v_local=$(dpkg -l | grep "^ii\s*tabby" | awk '{print $3}')
    local v_remote_tag
    v_remote_tag=$(gh_get_latest_tag "$repo")
    local v_remote="${v_remote_tag#v}"
    
    if [[ "$v_local" == *"$v_remote"* ]]; then
      log_info "Tabby is up to date ($v_local). Skipping."
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
  
  local tmp_deb="/tmp/tabby_install.deb"
  log_cmd "Downloading Tabby" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  rm -f "$tmp_deb"
}

mod_uninstall() {
  log_info "Uninstalling Tabby..."
  log_cmd "Purging tabby" sudo apt-get purge -y tabby
}

register_module
