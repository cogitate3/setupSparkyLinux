MOD_ID="pot"
MOD_NAME="Pot Desktop"
MOD_DESC="A cross-platform translator application."
MOD_GROUP="Desktop Apps"

mod_check() {
  command -v pot >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "xapp" "libxapp1" "libxapp-gtk3-module" "curl"

  local repo="pot-app/pot-desktop"
  
  if check_pkg_installed "pot"; then    
    local v_local
    v_local=$(dpkg -l | grep "^ii\s*pot" | awk '{print $3}')
    
    local v_remote_tag
    v_remote_tag=$(gh_get_latest_tag "$repo")
    local v_remote="${v_remote_tag#v}"
    
    # dpkg version might differ slightly in format, but simple check helps
    if [[ "$v_local" == *"$v_remote"* ]]; then
      log_info "Pot is up to date ($v_local). Skipping."
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
  
  local tmp_deb="/tmp/pot_install.deb"
  log_cmd "Downloading Pot Desktop" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  
  rm -f "$tmp_deb"
}

mod_uninstall() {
  log_info "Uninstalling Pot Desktop..."
  log_cmd "Purging pot" sudo apt-get purge -y pot
}

register_module
