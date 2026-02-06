MOD_ID="zsh"
MOD_NAME="Zsh Integration"
MOD_DESC="Installs Zsh, Oh My Zsh, plugins (autosuggestions, syntax-highlighting), and Powerlevel10k theme."
MOD_GROUP="Shell"

mod_check() {
  command -v zsh >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "zsh")
  local v_remote=$(apt-cache policy "zsh" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
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
  ensure_pkg autojump || log_warn "autojump installation failed, skipping"

  # 2. Install Oh My Zsh (unattended)
  local omz_dir="$target_home/.oh-my-zsh"
  
  if [ "${FORCE_REINSTALL:-0}" = "1" ] && [ -d "$omz_dir" ]; then
      log_info "Force Reinstall: Removing existing Oh My Zsh directory..."
      sudo rm -rf "$omz_dir"
  fi

  if [ ! -d "$omz_dir" ]; then
    log_info "Installing Oh My Zsh..."
    # Use sudo -u to run as target user
    sudo -u "$target_user" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh < /dev/null)" "" --unattended
  else
    log_info "Oh My Zsh already installed."
  fi

  # 3. Install Plugins
  local custom_dir="${omz_dir}/custom"
  local plugins_dir="${custom_dir}/plugins"
  
  local p_autosug="$plugins_dir/zsh-autosuggestions"
  if [ ! -d "$p_autosug" ]; then
    git_clone "https://github.com/zsh-users/zsh-autosuggestions" "$p_autosug" "--depth=1"
  fi

  local p_syntax="$plugins_dir/zsh-syntax-highlighting"
  if [ ! -d "$p_syntax" ]; then
    git_clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$p_syntax" "--depth=1"
  fi

  # 4. Install Powerlevel10k
  local p10k_dir="${custom_dir}/themes/powerlevel10k"
  if [ ! -d "$p10k_dir" ]; then
    git_clone "https://github.com/romkatv/powerlevel10k.git" "$p10k_dir" "--depth=1"
  fi

  # 5. Configure .zshrc
  local zshrc="$target_home/.zshrc"
  
  # Ensure .zshrc exists (OMZ installer should have created it)
  if [ ! -f "$zshrc" ]; then
    sudo -u "$target_user" cp "$omz_dir/templates/zshrc.zsh-template" "$zshrc"
  fi

  # Update plugins list
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
     local p10k_url="https://raw.githubusercontent.com/cogitate3/setupSparkyLinux/refs/heads/main/config/.p10k.zsh"
     download_file "$p10k_url" "$p10k_cfg" || log_warn "Failed to download .p10k.zsh"
     chown "$target_user:$target_user" "$p10k_cfg"
     chown -R "$target_user:$target_user" "$omz_dir"
     
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

mod_uninstall() {
  local target_user
  target_user="$(get_real_user)"
  local target_home
  target_home="$(get_user_home "$target_user")"
  
  log_info "Uninstalling Zsh Config..."
  
  # 1. Revert Shell to bash
  local bash_bin
  bash_bin="$(command -v bash)"
  if [ -x "$bash_bin" ]; then
    log_info "Reverting shell to $bash_bin for $target_user"
    sudo chsh -s "$bash_bin" "$target_user"
  fi
  
  # 2. Remove Oh My Zsh
  local omz_dir="$target_home/.oh-my-zsh"
  if [ -d "$omz_dir" ]; then
    log_info "Removing Oh My Zsh..."
    sudo rm -rf "$omz_dir"
  fi
  
  # 3. Restore/Remove config
  if [ -f "$target_home/.zshrc" ]; then
      sudo mv "$target_home/.zshrc" "$target_home/.zshrc.bak"
      log_info "Backed up .zshrc to .zshrc.bak"
  fi
  
  sudo rm -f "$target_home/.p10k.zsh"
  
  # 4. Uninstall packages
  log_cmd "Removing zsh package" sudo apt-get purge -y zsh autojump < /dev/null
}

register_module
