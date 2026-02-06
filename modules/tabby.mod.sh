MOD_ID="tabby"
MOD_NAME="Tabby Terminal"
MOD_DESC="A highly configurable terminal emulator."
MOD_GROUP="Dev Tools"

mod_check() {
  if check_pkg_installed "tabby-terminal"; then return 0; fi
  return 1
}

mod_status() {
  local repo="Eugeny/tabby"
  local v_local=$(get_pkg_version "tabby-terminal")
  local v_remote_tag=$(gh_get_latest_tag "$repo")
  local v_remote="${v_remote_tag#v}"
  
  echo "$v_local|$v_remote"
  
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  local repo="Eugeny/tabby"

  local url
  url=$(gh_latest_asset_url "$repo" ".*linux-x64.*\.deb$")
  
  if [ -z "$url" ]; then
    log_err "Could not find .deb asset for $repo. Please check the repository for available formats."
    return 1
  fi
  
  local tmp_deb="/tmp/tabby_install.deb"
  log_stream "Downloading Tabby" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  rm -f "$tmp_deb"
}

mod_uninstall() {
  log_info "Uninstalling Tabby..."
  log_cmd "Purging tabby" sudo apt-get purge -y tabby-terminal < /dev/null
}

register_module
