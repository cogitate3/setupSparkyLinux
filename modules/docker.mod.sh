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
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    log_cmd "Creating keyring dir" sudo install -m 0755 -d /etc/apt/keyrings
    log_info "Adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
      log_cmd "Saving keys" sudo tee /etc/apt/keyrings/docker.asc > /dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.asc
  fi

  # 2. Add Repository
  local codename="bookworm"
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    log_info "Adding Docker repository..."
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $codename stable" | \
      log_cmd "Writing sources list" sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    log_cmd "Updating apt" sudo apt-get update
  fi

  # 3. Install
  ensure_pkg "docker-ce" "docker-ce-cli" "containerd.io" "docker-compose-plugin"

  # 4. Configure User
  local target_user="${SUDO_USER:-$USER}"
  log_info "Adding user $target_user to docker group..."
  log_cmd "Usermod docker" sudo usermod -aG docker "$target_user"

  # 5. Enable Service
  log_cmd "Enabling service" sudo systemctl enable --now docker
}

mod_uninstall() {
  log_info "Uninstalling Docker..."
  log_cmd "Purging docker packages" sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  log_cmd "Autoremoving" sudo apt-get autoremove -y
  
  log_info "Removing keys and repos..."
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/keyrings/docker.asc
  
  log_cmd "Updating apt" sudo apt-get update
}

register_module
