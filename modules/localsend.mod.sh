MOD_ID="localsend"
MOD_NAME="LocalSend"
MOD_DESC="Share files to nearby devices."
MOD_GROUP="Desktop Apps"

mod_check() {
  if check_pkg_installed "localsend"; then return 0; fi
  return 1
}

mod_status() {
  local repo="localsend/localsend"
  local v_local=$(get_pkg_version "localsend")
  local v_remote_tag=$(gh_get_latest_tag "$repo")
  local v_remote="${v_remote_tag#v}"
  
  echo "$v_local|$v_remote"
  
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  local repo="localsend/localsend"
  
  local url
  url=$(gh_latest_asset_url "$repo" ".*linux-x86-64.*\.deb$")
  
  if [ -z "$url" ]; then
    log_err "Could not find .deb asset for $repo. You may need to install via Flatpak or manual tarball."
    return 1
  fi
  
  local tmp_deb="/tmp/localsend_install.deb"
  log_stream "Downloading LocalSend" curl -L -o "$tmp_deb" "$url" < /dev/null
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  rm -f "$tmp_deb"
}

mod_uninstall() {
  log_info "Uninstalling LocalSend..."
  log_cmd "Purging localsend" sudo apt-get purge -y localsend < /dev/null
}

register_module
