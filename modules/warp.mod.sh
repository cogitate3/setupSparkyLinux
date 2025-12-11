MOD_ID="warp"
MOD_NAME="Warp Terminal"
MOD_DESC="The AI-powered terminal."
MOD_GROUP="Dev Tools"

mod_check() {
  if check_pkg_installed "warp-terminal"; then return 0; fi
  command -v warp-terminal >/dev/null 2>&1
}

mod_install() {
  local url="https://app.warp.dev/download?package=deb"
  
  if mod_check; then
    local v_local
    v_local=$(dpkg -l | grep "^ii\s*warp" | awk '{print $3}')
    log_info "Warp installed ($v_local). Re-installing to ensure latest..."
  fi

  local tmp_deb="/tmp/warp_install.deb"
  ensure_pkg "curl"
  
  log_cmd "Downloading Warp" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing Warp..."
  ensure_pkg "$tmp_deb"
  rm -f "$tmp_deb"
}

mod_uninstall() {
  log_info "Uninstalling Warp..."
  log_cmd "Purging warp-terminal" sudo apt-get purge -y warp-terminal
  # Note package name might be warp-terminal or warp, assuming standard deb naming
}

register_module
