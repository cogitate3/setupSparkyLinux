MOD_ID="stretchly"
MOD_NAME="Stretchly"
MOD_DESC="A break time reminder app."
MOD_GROUP="Desktop Apps"

mod_check() {
  if check_pkg_installed "stretchly"; then return 0; fi
  return 1
}

mod_status() {
  local repo="hovancik/stretchly"
  local v_local=$(get_pkg_version "stretchly")
  local v_remote_tag=$(gh_get_latest_tag "$repo")
  local v_remote="${v_remote_tag#v}"
  
  echo "$v_local|$v_remote"
  
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  local repo="hovancik/stretchly"

  local url
  url=$(gh_latest_asset_url "$repo" ".*amd64\.deb$")
  
  if [ -z "$url" ]; then
    log_err "Could not find .deb asset for $repo. Check if the project still provides Debian packages."
    return 1
  fi
  
  local tmp_deb="/tmp/stretchly_install.deb"
  log_stream "Downloading Stretchly" curl -L -o "$tmp_deb" "$url" < /dev/null
  
  log_info "Installing package..."
  ensure_pkg "$tmp_deb"
  rm -f "$tmp_deb"
}

mod_uninstall() {
  log_info "Uninstalling Stretchly..."
  log_cmd "Purging stretchly" sudo apt-get purge -y stretchly < /dev/null
}

register_module
