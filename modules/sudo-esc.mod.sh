MOD_ID="sudo-esc"
MOD_NAME="Double-ESC Sudo"
MOD_DESC="Press ESC twice to prepend 'sudo' to the current command."
MOD_GROUP="System"

mod_check() {
  # Check if config exists in .bashrc OR .zshrc (any existing config is considered "installed")
  if [ -f "$HOME/.bashrc" ] && grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$HOME/.bashrc"; then return 0; fi
  if [ -f "$HOME/.zshrc" ] && grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$HOME/.zshrc"; then return 0; fi
  return 1
}

mod_status() {
  if mod_check; then
    echo "active|latest"
    return 0
  fi
  echo "none|latest"
  return 2
}

mod_install() {
  local installed_any=0

  # --- BASH SETUP ---
  if command -v bash >/dev/null 2>&1; then
    local bash_rc="$HOME/.bashrc"
    # Ensure file exists
    [ ! -f "$bash_rc" ] && touch "$bash_rc"
    
    if ! grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$bash_rc"; then
      log_info "Adding configuration to $bash_rc (Bash)..."
      cat << 'EOF' >> "$bash_rc"

# BEGIN DOUBLE-ESC-SUDO CONFIG
double_esc_to_sudo() {
    if [[ $SHELL =~ (bash) ]]; then
        if [[ "$READLINE_LINE" != sudo\ * ]]; then
            READLINE_POINT=0
            READLINE_LINE="sudo $READLINE_LINE"
            return 0
        fi
    fi
    return 1
}
bind -x '"\e\e":double_esc_to_sudo'
# END DOUBLE-ESC-SUDO CONFIG
EOF
      installed_any=1
    else
      log_info "Configuration already in $bash_rc"
      installed_any=1
    fi
  else
    log_warn "Bash not found, skipping Bash configuration."
  fi

  # --- ZSH SETUP ---
  if command -v zsh >/dev/null 2>&1; then
    local zsh_rc="$HOME/.zshrc"
    # Ensure file exists
    [ ! -f "$zsh_rc" ] && touch "$zsh_rc"

    if ! grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$zsh_rc"; then
      log_info "Adding configuration to $zsh_rc (Zsh)..."
      cat << 'EOF' >> "$zsh_rc"

# BEGIN DOUBLE-ESC-SUDO CONFIG
double_esc_sudo() {
  if [[ $BUFFER != sudo\ * ]]; then
    BUFFER="sudo $BUFFER"
    CURSOR=$((CURSOR+5))
  fi
}
zle -N double_esc_sudo
bindkey '\e\e' double_esc_sudo
# END DOUBLE-ESC-SUDO CONFIG
EOF
      installed_any=1
    else
      log_info "Configuration already in $zsh_rc"
      installed_any=1
    fi
  else
    log_info "Zsh not found, skipping Zsh configuration."
  fi
  
  if [ $installed_any -eq 1 ]; then
    log_info "Double-ESC Sudo setup complete."
    log_info "Please restart your shell(s) for changes to take effect."
  else
    log_warn "No suitable shells found or configured."
  fi
}

mod_uninstall() {
  local removed=0

  # Remove from Bash
  if [ -f "$HOME/.bashrc" ] && grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$HOME/.bashrc"; then
    log_info "Removing configuration from $HOME/.bashrc..."
    sed -i '/# BEGIN DOUBLE-ESC-SUDO CONFIG/,/# END DOUBLE-ESC-SUDO CONFIG/d' "$HOME/.bashrc"
    removed=1
  fi

  # Remove from Zsh
  if [ -f "$HOME/.zshrc" ] && grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$HOME/.zshrc"; then
    log_info "Removing configuration from $HOME/.zshrc..."
    sed -i '/# BEGIN DOUBLE-ESC-SUDO CONFIG/,/# END DOUBLE-ESC-SUDO CONFIG/d' "$HOME/.zshrc"
    removed=1
  fi
  
  if [ $removed -eq 1 ]; then
    log_info "Uninstall complete. Please restart your shells."
  else
    log_info "No configuration found to remove."
  fi
}

register_module
