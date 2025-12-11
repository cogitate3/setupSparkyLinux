MOD_ID="fonts"
MOD_NAME="Fonts & Typography"
MOD_DESC="Installs programming fonts (JetBrains Mono, FiraCode), CJK fonts, and font tools."
MOD_GROUP="Appearance"

mod_check() {
  # Check for a key font package or command. fnt is a good indicator.
  if command -v fnt >/dev/null 2>&1; then
      return 0
  fi
  return 1
}

mod_install() {
  local pkgs=(
    fnt
    fonts-jetbrains-mono
    fonts-hack-otf fonts-hack-ttf
    fonts-lxgw-wenkai fonts-wqy-microhei fonts-wqy-zenhei
    fonts-noto-cjk-extra fonts-noto-mono fonts-firacode
    fonts-noto-color-emoji fonts-symbola
  )

  for p in "${pkgs[@]}"; do
    ensure_pkg "$p"
  done

  log_cmd "Updating font cache" fc-cache -f
}
register_module
