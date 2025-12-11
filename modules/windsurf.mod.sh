MOD_ID="windsurf"
MOD_NAME="Windsurf IDE"
MOD_DESC="An AI-powered Code Editor."
MOD_GROUP="Dev Tools"

mod_check() {
  command -v windsurf >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "curl" "gnupg"

  if [ ! -f /etc/apt/sources.list.d/windsurf.list ]; then
    log_info "Adding Windsurf GPG key..."
    curl -fsSL "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | \
      log_cmd "Saving GPG key" sudo gpg --dearmor --yes -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg

    log_info "Adding Windsurf repository..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | \
      log_cmd "Writing sources list" sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null

    log_cmd "Updating apt" sudo apt-get update
  fi
  
  ensure_pkg "windsurf"
}

mod_uninstall() {
  log_info "Uninstalling Windsurf..."
  log_cmd "Purging windsurf" sudo apt-get purge -y windsurf
  
  log_info "Removing repository..."
  sudo rm -f /etc/apt/sources.list.d/windsurf.list
  sudo rm -f /usr/share/keyrings/windsurf-stable-archive-keyring.gpg
  
  log_cmd "Updating apt" sudo apt-get update
}

register_module
