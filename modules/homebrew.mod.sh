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

  log_info "Running Homebrew install script..."
  # Use NONINTERACTIVE=1 to avoid prompts
  log_cmd "Installing Homebrew" /bin/bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Configure PATH
  # This part is a bit intrusive for a module, but essential for brew to work.
  # We'll follow legacy logic and append to rc files safe-ishly.
  
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

register_module
