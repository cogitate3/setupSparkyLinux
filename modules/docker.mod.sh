MOD_ID="docker"
MOD_NAME="Docker"
MOD_DESC="Containerization platform."
MOD_GROUP="System"

mod_check() {
  if command -v docker >/dev/null 2>&1; then return 0; fi
  if check_pkg_installed "docker-ce"; then return 0; fi
  return 1
}

mod_install() {
  ensure_pkg "apt-transport-https" "ca-certificates" "curl" "gnupg" "lsb-release"

  # 1. Add GPG Key
  log_cmd "Creating keyring dir" sudo install -m 0755 -d /etc/apt/keyrings
  log_info "Adding Docker GPG key..."
  curl -fsSL https://download.docker.com/linux/debian/gpg | \
    log_cmd "Saving keys" sudo tee /etc/apt/keyrings/docker.asc > /dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # 2. Add Repository
  # Use hardcoded codename 'bookworm' as per legacy request or detect?
  # Legacy said "system version codename: bookworm" specifically.
  local codename="bookworm"
  # Or use $(lsb_release -cs) if we want to be dynamic, but let's stick to legacy consistency for now.
  
  log_info "Adding Docker repository..."
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $codename stable" | \
    log_cmd "Writing sources list" sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # 3. Install
  log_cmd "Updating apt" sudo apt-get update
  ensure_pkg "docker-ce" "docker-ce-cli" "containerd.io" "docker-compose-plugin"

  # 4. Configure User
  local target_user="${SUDO_USER:-$USER}"
  log_info "Adding user $target_user to docker group..."
  log_cmd "Usermod docker" sudo usermod -aG docker "$target_user"

  # 5. Enable Service
  log_cmd "Enabling service" sudo systemctl enable --now docker
}

register_module
