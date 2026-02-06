MOD_ID="fsearch"
MOD_NAME="FSearch"
MOD_DESC="A fast file search utility (similar to Everything on Windows)."
MOD_GROUP="Desktop Apps"

mod_check() {
  command -v fsearch >/dev/null 2>&1
}

mod_status() {
  local pkg="fsearch"
  if ! check_pkg_installed "$pkg"; then return 2; fi
  
  local v_local=$(get_pkg_version "$pkg")
  local v_remote=$(apt-cache policy "$pkg" | grep "Candidate:" | awk '{print $2}' | sed -E 's/^[0-9]+://;s/-.*//')
  
  echo "$v_local|$v_remote"
  
  if [ -n "$v_remote" ] && [ "$v_remote" != "$v_local" ]; then
    return 1 # Update available
  fi
  return 0 # Up to date
}

mod_install() {
  # 1. Install Dependencies
  ensure_pkg "curl" "gpg"

  # 2. Add Repository (idempotent logic)
  if [ ! -f /etc/apt/sources.list.d/home:cboxdoerfer.list ]; then
    log_info "Adding FSearch repository..."
    echo 'deb http://download.opensuse.org/repositories/home:/cboxdoerfer/Debian_12/ /' | \
      log_cmd "Adding apt source" sudo tee /etc/apt/sources.list.d/home:cboxdoerfer.list
      
    log_info "Adding GPG key..."
    curl -fsSL https://download.opensuse.org/repositories/home:cboxdoerfer/Debian_12/Release.key < /dev/null | \
      gpg --dearmor | \
      log_cmd "Adding GPG key" sudo tee /etc/apt/trusted.gpg.d/home_cboxdoerfer.gpg > /dev/null
      
    log_cmd "Updating apt" sudo apt-get update < /dev/null
  fi

  # 3. Install
  ensure_pkg "fsearch"
}

mod_uninstall() {
  log_info "Uninstalling FSearch..."
  log_cmd "Purging fsearch" sudo apt-get purge -y fsearch < /dev/null
  
  log_info "Removing repository..."
  sudo rm -f /etc/apt/sources.list.d/home:cboxdoerfer.list
  sudo rm -f /etc/apt/trusted.gpg.d/home_cboxdoerfer.gpg
  
  log_cmd "Updating apt" sudo apt-get update < /dev/null
}

register_module
