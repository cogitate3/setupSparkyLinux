MOD_ID="brave"
MOD_NAME="Brave Browser"
MOD_DESC="A privacy-focused web browser."
MOD_GROUP="Browsers"

mod_check() {
  command -v brave-browser >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "brave-browser")
  local v_remote=$(apt-cache policy "brave-browser" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "curl"

  # Keyring / Repo logic (idempotent)
  if [ ! -f /etc/apt/sources.list.d/brave-browser-release.list ]; then
    if [ ! -d "/usr/share/keyrings" ]; then
      log_cmd "Creating keyrings dir" sudo mkdir -p /usr/share/keyrings
    fi

    log_info "Adding Brave GPG key..."
    curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg < /dev/null | \
      log_cmd "Saving GPG key" sudo tee /usr/share/keyrings/brave-browser-archive-keyring.gpg > /dev/null

    log_info "Adding Brave repository..."
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
      log_cmd "Writing sources list" sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null

    log_cmd "Updating apt" sudo apt-get update < /dev/null
  fi

  ensure_pkg "brave-browser"
}

mod_uninstall() {
  log_info "Uninstalling Brave Browser..."
  log_cmd "Purging brave-browser" sudo apt-get purge -y brave-browser < /dev/null
  
  log_info "Removing repository..."
  sudo rm -f /etc/apt/sources.list.d/brave-browser-release.list
  sudo rm -f /usr/share/keyrings/brave-browser-archive-keyring.gpg
  
  log_cmd "Updating apt" sudo apt-get update < /dev/null
}

register_module
