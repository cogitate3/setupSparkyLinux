MOD_ID="cheat"
MOD_NAME="Cheat.sh"
MOD_DESC="Unified access to the best community driven cheat sheets repositories in the world."
MOD_GROUP="CLI Tools"

mod_check() {
  if [ -x "$HOME/.local/bin/cht.sh" ]; then return 0; fi # User install
  if [ -x "/usr/local/bin/cht.sh" ]; then return 0; fi # Global install fallback
  if command -v cht.sh >/dev/null 2>&1; then return 0; fi
  return 1
}

mod_install() {
  ensure_pkg "rlwrap" "curl"
  
  # No robust version check for cheat.sh script itself usually, 
  # but we can re-download if user requests install/update.
  
  local bin_path="$HOME/.local/bin/cht.sh"
  mkdir -p "$HOME/.local/bin"
  
  log_info "Installing/Updating cht.sh..."
  log_cmd "Downloading cht.sh" curl -Ls https://cht.sh/:cht.sh -o "$bin_path"
  chmod +x "$bin_path"
  
  local bash_comp_dir="$HOME/.bash.d"
  local zsh_comp_dir="$HOME/.zsh.d"
  mkdir -p "$bash_comp_dir" "$zsh_comp_dir"
  
  log_info "Updating completions..."
  curl -s https://cheat.sh/:bash_completion -o "$bash_comp_dir/cht.sh"
  curl -s https://cheat.sh/:zsh -o "$zsh_comp_dir/_cht"
  
  log_info "Installed cht.sh to $bin_path"
}

mod_uninstall() {
  log_info "Uninstalling Cheat.sh..."
  rm -f "$HOME/.local/bin/cht.sh"
  rm -f "$HOME/.bash.d/cht.sh"
  rm -f "$HOME/.zsh.d/_cht"
}

register_module
