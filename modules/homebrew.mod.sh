MOD_ID="homebrew"
MOD_NAME="Homebrew"
MOD_DESC="The Missing Package Manager for macOS (or Linux)."
MOD_GROUP="System"

mod_check() {
  if command -v brew >/dev/null 2>&1; then return 0; fi
  if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then return 0; fi
  return 1
}

mod_install() {
  ensure_pkg "curl" "git"
  
  if mod_check; then
    log_info "Homebrew is installed. Updating..."
    # brew update might work if in path, or call directly
    local brew_bin="/home/linuxbrew/.linuxbrew/bin/brew"
    if [ -x "$brew_bin" ]; then
      log_cmd "Updating brew" "$brew_bin" update
    fi
    return 0
  fi

  log_info "Running Homebrew install script..."
  log_cmd "Installing Homebrew" /bin/bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  local brew_bin="/home/linuxbrew/.linuxbrew/bin/brew"
  if [ -x "$brew_bin" ]; then
    log_info "Configuring shell environment..."
    local shell_env_cmd='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    
    local files=()
    [ -f "$HOME/.bashrc" ] && files+=("$HOME/.bashrc")
    [ -f "$HOME/.zshrc" ] && files+=("$HOME/.zshrc")
    
    for rc in "${files[@]}"; do
      if ! grep -Fq "$brew_bin" "$rc"; then
         log_info "Adding brew shellenv to $rc"
         echo "$shell_env_cmd" >> "$rc"
      fi
    done
  else
    log_warn "Homebrew binary not found at standard location, skipping path config."
  fi
}

mod_uninstall() {
  log_info "Uninstalling Homebrew..."
  # Official uninstall script
  # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  # We should probably run it non-interactively if possible or just warn user.
  
  log_warn "Homebrew uninstallation requires interaction usually. Attempting non-interactive defaults..."
  # NONINTERACTIVE=1 might not work for uninstall script
  
  if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
     echo "y" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
  else
     log_info "Homebrew not found in default location."
  fi
  
  # Remove shell config
  # Cleaning up rc files is complex via sed if line matches specific string.
  # We'll skip invasive sed for now or use a careful delete.
}

register_module
