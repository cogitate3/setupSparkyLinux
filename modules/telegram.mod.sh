MOD_ID="telegram"
MOD_NAME="Telegram"
MOD_DESC="Official Telegram Desktop messaging app."
MOD_GROUP="System"

mod_check() {
  if [ -x "/opt/Telegram/Telegram" ]; then return 0; fi
  if command -v telegram-desktop >/dev/null 2>&1; then return 0; fi
  return 1
}

mod_status() {
  local v_local="unknown"
  if [ -x "/opt/Telegram/Telegram" ]; then
    # Telegram binary doesn't output version easily, but let's assume if it exists, it's there.
    # We can rely on internal updater.
    v_local="installed"
  elif command -v telegram-desktop >/dev/null 2>&1; then
    v_local=$(get_pkg_version "telegram-desktop")
  fi
  
  # Official download is always "latest"
  local v_remote="latest"
  
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  # For manual install, we just say it's up to date and let app handle it, or force update if user wants.
  # But technically we can't compare.
  return 0 
}

mod_install() {
  ensure_pkg "curl" "xz-utils"
  
  local url="https://telegram.org/dl/desktop/linux"
  local tmp_file="/tmp/telegram.tar.xz"
  
  download_file "$url" "$tmp_file"
  
  log_info "Installing to /opt/Telegram..."
  sudo tar -xf "$tmp_file" -C /opt/
  
  log_cmd "Linking binary" sudo ln -sf /opt/Telegram/Telegram /usr/bin/telegram-desktop
  
  # Create Desktop Entry
  cat <<EOF | sudo tee /usr/share/applications/telegram-desktop.desktop >/dev/null
[Desktop Entry]
Version=1.0
Name=Telegram Desktop
Comment=Official Telegram Desktop
Exec=/opt/Telegram/Telegram -- %u
Icon=telegram
Terminal=false
StartupWMClass=TelegramDesktop
Type=Application
Categories=Chat;Network;InstantMessaging;Qt;
MimeType=x-scheme-handler/tg;
EOF

  rm -f "$tmp_file"
}

mod_uninstall() {
  log_info "Uninstalling Telegram..."
  sudo rm -rf /opt/Telegram
  sudo rm -f /usr/bin/telegram-desktop
  sudo rm -f /usr/share/applications/telegram-desktop.desktop
}

register_module
