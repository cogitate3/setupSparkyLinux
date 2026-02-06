MOD_ID="wps"
MOD_NAME="WPS Office"
MOD_DESC="An office productivity suite."
MOD_GROUP="Desktop Apps"

mod_check() {
  command -v wps >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "wps-office")
  local v_remote="12.8.2.19829"
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  if mod_check; then
     log_info "WPS Office is installed. Reinstalling/Updating..."
  fi

  local url="https://wps-linux-365.wpscdn.cn/wps/download/ep/Linux365/19829/wps-office_12.8.2.19829.AK.preload.sw_amd64.deb"
  local tmp_deb="/tmp/wps_install.deb"
  
  ensure_pkg "wget"
  
  download_file "$url" "$tmp_deb"
  
  log_info "Installing WPS Office..."
  ensure_pkg "$tmp_deb"
  
  log_info "Preventing WPS auto-update (holding package)..."
  sudo apt-mark hold wps-office
  rm -f "$tmp_deb"
}

mod_uninstall() {
  log_info "Uninstalling WPS Office..."
  sudo apt-mark unhold wps-office
  log_cmd "Purging wps-office" sudo apt-get purge -y wps-office < /dev/null
  
  # Clean fonts or others? Legacy didn't specify.
}

register_module
