MOD_ID="fonts"
MOD_NAME="Fonts & Typography"
MOD_DESC="Install popular fonts (Microsoft, Nerd Fonts, etc)."
MOD_GROUP="Appearance"

mod_check() {
  if [ -d "$HOME/.local/share/fonts/NerdFonts" ]; then return 0; fi
  return 1
}

mod_install() {
  local font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"
  
  ensure_pkg "curl" "unzip" "fontconfig"

  # 1. Nerd Fonts (e.g., JetBrainsMono)
  local nerd_ver="v3.0.2"
  local nerd_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${nerd_ver}/JetBrainsMono.zip"
  
  log_info "Downloading JetBrainsMono Nerd Font..."
  local tmp_zip="/tmp/jb_nerd.zip"
  curl -L -o "$tmp_zip" "$nerd_url"
  
  unzip -o "$tmp_zip" -d "$font_dir/NerdFonts"
  rm -f "$tmp_zip"

  # 2. MS Fonts (msttcorefonts)
  ensure_pkg "ttf-mscorefonts-installer"

  log_info "Rebuilding font cache..."
  fc-cache -fv
}

mod_uninstall() {
  log_info "Uninstalling Fonts..."
  rm -rf "$HOME/.local/share/fonts/NerdFonts"
  
  # msttcorefonts removal
  sudo apt-get purge -y ttf-mscorefonts-installer
  
  log_info "Rebuilding font cache..."
  fc-cache -fv
}

register_module
