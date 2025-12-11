MOD_ID="cheat"
MOD_NAME="Cheat.sh"
MOD_DESC="Unified access to the best community driven cheat sheets repositories in the world."
MOD_GROUP="CLI Tools"

mod_check() {
  if [ -x "$HOME/.local/bin/cht.sh" ]; then return 0; fi
  if command -v cht.sh >/dev/null 2>&1; then return 0; fi
  return 1
}

mod_install() {
  ensure_pkg "rlwrap" "curl"
  
  mkdir -p "$HOME/.local/bin"
  
  log_info "Installing cht.sh..."
  log_cmd "Downloading cht.sh" curl -Ls https://cht.sh/:cht.sh -o "$HOME/.local/bin/cht.sh"
  chmod +x "$HOME/.local/bin/cht.sh"
  
  # Ensure path in .bashrc/.zshrc if not present is tricky without direct edits, 
  # but standard .profile often includes ~/.local/bin.
  # We will stick to file installation as per legacy mostly.
  
  local bash_comp_dir="$HOME/.bash.d"
  local zsh_comp_dir="$HOME/.zsh.d"
  mkdir -p "$bash_comp_dir" "$zsh_comp_dir"
  
  log_info "Installing completions..."
  curl -s https://cheat.sh/:bash_completion -o "$bash_comp_dir/cht.sh"
  
  curl -s https://cheat.sh/:zsh -o "$zsh_comp_dir/_cht"
  
  # Note: The user needs to source these in their rc files.
  # Legacy script did append to .bashrc/.zshrc. We can do that carefully or leave it to the user.
  # For now, let's keep it simple and just install the files.
  
  log_info "Installed cht.sh to ~/.local/bin/cht.sh"
}

register_module
