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

  # 2. Add Repository (logic ported from legacy)
  log_info "Adding FSearch repository..."
  echo 'deb http://download.opensuse.org/repositories/home:/cboxdoerfer/Debian_12/ /' | \
    log_cmd "Adding apt source" sudo tee /etc/apt/sources.list.d/home:cboxdoerfer.list

  # 3. Add Key
  log_info "Adding GPG key..."
  curl -fsSL https://download.opensuse.org/repositories/home:cboxdoerfer/Debian_12/Release.key | \
    gpg --dearmor | \
    log_cmd "Adding GPG key" sudo tee /etc/apt/trusted.gpg.d/home_cboxdoerfer.gpg > /dev/null

  # 4. Install
  log_cmd "Updating apt" sudo apt-get update
  ensure_pkg "fsearch"
}

register_module
