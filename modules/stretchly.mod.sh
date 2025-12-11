MOD_ID="stretchly"
MOD_NAME="Stretchly"
MOD_DESC="A break time reminder app."
MOD_GROUP="Desktop Apps"

mod_check() {
  if check_pkg_installed "stretchly"; then return 0; fi
  return 1
}

mod_install() {
  local repo="hovancik/stretchly"
  
  if mod_check; then
    local v_local
    v_local=$(dpkg -l | grep "^ii\s*stretchly" | awk '{print $3}')
    local v_remote_tag
    v_remote_tag=$(gh_get_latest_tag "$repo")
    local v_remote="${v_remote_tag#v}"
    
    if [[ "$v_local" == *"$v_remote"* ]]; then
      log_info "Stretchly is up to date ($v_local). Skipping."
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
  
  local tmp_deb="/tmp/stretchly_install.deb"
  log_cmd "Downloading Stretchly" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  rm -f "$tmp_deb"
}

mod_uninstall() {
  log_info "Uninstalling Stretchly..."
  log_cmd "Purging stretchly" sudo apt-get purge -y stretchly
}

register_module
