MOD_ID="sudo-esc"
MOD_NAME="Double-ESC Sudo"
MOD_DESC="Press ESC twice to prepend 'sudo' to the current command."
MOD_GROUP="System"

mod_check() {
  # Check if config exists in .bashrc or .zshrc
  local shell_rc=""
  if [ -n "$BASH_VERSION" ]; then shell_rc="$HOME/.bashrc"; fi
  if [ -n "$ZSH_VERSION" ]; then shell_rc="$HOME/.zshrc"; fi
  
  # Fallback check both if we are running in a script not interactive
  if grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$HOME/.bashrc" 2>/dev/null; then return 0; fi
  if grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$HOME/.zshrc" 2>/dev/null; then return 0; fi
  
  return 1
}

mod_install() {
  local files=()
  [ -f "$HOME/.bashrc" ] && files+=("$HOME/.bashrc")
  [ -f "$HOME/.zshrc" ] && files+=("$HOME/.zshrc")
  
  for rc_file in "${files[@]}"; do
    if ! grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$rc_file"; then
      log_info "Adding configuration to $rc_file..."
      cat << 'EOF' >> "$rc_file"

# BEGIN DOUBLE-ESC-SUDO CONFIG
double_esc_to_sudo() {
    if [[ $SHELL =~ (bash|zsh) ]]; then
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
    else
      log_info "Configuration already in $rc_file"
    fi
  done
  
  log_info "Please restart your shell or run 'source ~/.bashrc' (or zshrc) to take effect."
}

mod_uninstall() {
  local files=()
  [ -f "$HOME/.bashrc" ] && files+=("$HOME/.bashrc")
  [ -f "$HOME/.zshrc" ] && files+=("$HOME/.zshrc")
  
  for rc_file in "${files[@]}"; do
    if grep -q "# BEGIN DOUBLE-ESC-SUDO CONFIG" "$rc_file"; then
      log_info "Removing configuration from $rc_file..."
      # Use sed to delete the block
      sed -i '/# BEGIN DOUBLE-ESC-SUDO CONFIG/,/# END DOUBLE-ESC-SUDO CONFIG/d' "$rc_file"
    fi
  done
}

register_module
