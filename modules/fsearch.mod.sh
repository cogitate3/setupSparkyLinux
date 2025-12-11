MOD_ID="fsearch"
MOD_NAME="FSearch"
MOD_DESC="A fast file search utility (similar to Everything on Windows)."
MOD_GROUP="Desktop Apps"

mod_check() {
  command -v fsearch >/dev/null 2>&1
}

mod_install() {
  # 1. Install Dependencies
  ensure_pkg "curl" "apt-transport-https" "software-properties-common" "gpg"

  # 2. Add Repository (idempotent logic)
  if [ ! -f /etc/apt/sources.list.d/home:cboxdoerfer.list ]; then
    log_info "Adding FSearch repository..."
    echo 'deb http://download.opensuse.org/repositories/home:/cboxdoerfer/Debian_12/ /' | \
      log_cmd "Adding apt source" sudo tee /etc/apt/sources.list.d/home:cboxdoerfer.list
      
    log_info "Adding GPG key..."
    curl -fsSL https://download.opensuse.org/repositories/home:cboxdoerfer/Debian_12/Release.key | \
      gpg --dearmor | \
      log_cmd "Adding GPG key" sudo tee /etc/apt/trusted.gpg.d/home_cboxdoerfer.gpg > /dev/null
      
    log_cmd "Updating apt" sudo apt-get update
  fi

  # 3. Install
  ensure_pkg "fsearch"
}

mod_uninstall() {
  log_info "Uninstalling FSearch..."
  log_cmd "Purging fsearch" sudo apt-get purge -y fsearch
  
  log_info "Removing repository..."
  sudo rm -f /etc/apt/sources.list.d/home:cboxdoerfer.list
  sudo rm -f /etc/apt/trusted.gpg.d/home_cboxdoerfer.gpg
  
  log_cmd "Updating apt" sudo apt-get update
}

register_module
