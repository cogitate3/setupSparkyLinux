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
  # Legacy script scraped for link, but the direct link usually redirects to latest.
  # Let's trust curl -L handles it or simple wget.
  
  local tmp_deb="/tmp/warp_install.deb"
  ensure_pkg "curl"
  
  log_cmd "Downloading Warp" curl -L -o "$tmp_deb" "$url"
  
  log_info "Installing Warp..."
  ensure_pkg "$tmp_deb"
  
  rm -f "$tmp_deb"
}

register_module
