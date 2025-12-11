MOD_ID="zsh"
MOD_NAME="Zsh Integration"
MOD_DESC="Installs Zsh, Oh My Zsh, plugins (autosuggestions, syntax-highlighting), and Powerlevel10k theme."
MOD_GROUP="Shell"

mod_check() {
  command -v zsh >/dev/null 2>&1
}

get_real_user() {
  if [ -n "${SUDO_USER:-}" ]; then
    echo "$SUDO_USER"
  else
    echo "${USER:-$(whoami)}"
  fi
}

get_user_home() {
  local user="$1"
  getent passwd "$user" | cut -d: -f6
}

mod_install() {
  local target_user
  target_user="$(get_real_user)"
  local target_home
  target_home="$(get_user_home "$target_user")"

  log_info "Target user: $target_user ($target_home)"

  # 1. Install packages
  ensure_pkg zsh
  ensure_pkg git
  ensure_pkg curl
  ensure_pkg fzf
  # autojump might not be in all repos, but usually is.
  # If fails, we might want to skip or warn? ensure_pkg errors out.
  ensure_pkg autojump || log_warn "autojump installation failed, skipping"

  # 2. Install Oh My Zsh (unattended)
  local omz_dir="$target_home/.oh-my-zsh"
  if [ ! -d "$omz_dir" ]; then
    log_info "Installing Oh My Zsh..."
    # Use sudo -u to run as target user
    sudo -u "$target_user" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    log_info "Oh My Zsh already installed."
  fi

  # 3. Install Plugins
  local custom_dir="${omz_dir}/custom"
  local plugins_dir="${custom_dir}/plugins"
  
  local p_autosug="$plugins_dir/zsh-autosuggestions"
  if [ ! -d "$p_autosug" ]; then
    log_cmd "Installing zsh-autosuggestions" \
      sudo -u "$target_user" git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$p_autosug"
  fi

  local p_syntax="$plugins_dir/zsh-syntax-highlighting"
  if [ ! -d "$p_syntax" ]; then
    log_cmd "Installing zsh-syntax-highlighting" \
      sudo -u "$target_user" git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$p_syntax"
  fi

  # 4. Install Powerlevel10k
  local p10k_dir="${custom_dir}/themes/powerlevel10k"
  if [ ! -d "$p10k_dir" ]; then
    log_cmd "Installing Powerlevel10k" \
      sudo -u "$target_user" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
  fi

  # 5. Configure .zshrc
  local zshrc="$target_home/.zshrc"
  
  # Ensure .zshrc exists (OMZ installer should have created it)
  if [ ! -f "$zshrc" ]; then
    sudo -u "$target_user" cp "$omz_dir/templates/zshrc.zsh-template" "$zshrc"
  fi

  # Update plugins list
  # We use sed to replace the default plugins line or just ensure ours are there.
  # This is a bit brittle with sed, but matching the default template:
  # plugins=(git)
  # We want: plugins=(git zsh-autosuggestions zsh-syntax-highlighting autojump fzf)
  local new_plugins="plugins=(git zsh-autosuggestions zsh-syntax-highlighting autojump fzf)"
  
  if grep -q "^plugins=(" "$zshrc"; then
     log_info "Updating plugins in .zshrc"
     sudo -u "$target_user" sed -i "s/^plugins=(.*)/$new_plugins/" "$zshrc"
  else
     echo "$new_plugins" | sudo -u "$target_user" tee -a "$zshrc"
  fi

  # Update Theme
  if grep -q "^ZSH_THEME=" "$zshrc"; then
    sudo -u "$target_user" sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc"
  fi
  
  # Download .p10k.zsh config if missing
  local p10k_cfg="$target_home/.p10k.zsh"
  if [ ! -f "$p10k_cfg" ]; then
     log_info "Downloading standard .p10k.zsh..."
     # Using the URL from legacy script
     local p10k_url="https://raw.githubusercontent.com/cogitate3/setupSparkyLinux/refs/heads/main/config/.p10k.zsh"
     sudo -u "$target_user" curl -fsSL -o "$p10k_cfg" "$p10k_url" || log_warn "Failed to download .p10k.zsh"
     
     # Add source command to zshrc if not present
     if ! grep -q "source ~/.p10k.zsh" "$zshrc"; then
       echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' | sudo -u "$target_user" tee -a "$zshrc"
     fi
  fi

  # 6. Change Shell
  local zsh_bin
  zsh_bin="$(command -v zsh)"
  if [ "$SHELL" != "$zsh_bin" ]; then
    if ! grep -q "$zsh_bin" /etc/shells; then
       echo "$zsh_bin" | sudo tee -a /etc/shells
    fi
    log_info "Changing shell to $zsh_bin for $target_user"
    sudo chsh -s "$zsh_bin" "$target_user"
  fi

  log_info "Zsh setup complete. Please log out and back in."
}
register_module
