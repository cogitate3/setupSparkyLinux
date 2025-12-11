MOD_ID="wps"
MOD_NAME="WPS Office"
MOD_DESC="An office productivity suite."
MOD_GROUP="Desktop Apps"

mod_check() {
  command -v wps >/dev/null 2>&1
}

mod_install() {
  # URL copied from legacy/901afterLinuxInstall.sh
  # This uses a specific version. In a real scenario, we might want to check for updates, 
  # but WPS download links are not easily crawlable via GitHub API.
  local url="https://wps-linux-365.wpscdn.cn/wps/download/ep/Linux365/19829/wps-office_12.8.2.19829.AK.preload.sw_amd64.deb"
  local tmp_deb="/tmp/wps_install.deb"
  
  ensure_pkg "wget"
  
  log_cmd "Downloading WPS Office" wget -O "$tmp_deb" "$url"
  
  log_info "Installing WPS Office..."
  ensure_pkg "$tmp_deb"
  
  log_info "Preventing WPS auto-update (holding package)..."
  sudo apt-mark hold wps-office
  
  rm -f "$tmp_deb"
}

register_module
