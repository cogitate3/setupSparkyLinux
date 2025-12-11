MOD_ID="rime"
MOD_NAME="Rime Input Method (Fcitx5)"
MOD_DESC="Installs Fcitx5 and Rime with the 'rime-ice' configuration."
MOD_GROUP="Input Method"

mod_check() {
  if command -v fcitx5 >/dev/null 2>&1; then
      return 0
  fi
  return 1
}

mod_install() {
  # 1. Install packages
  local pkgs=(
    fcitx5 fcitx5-rime fcitx5-chinese-addons
    fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-qt5
    fcitx5-module-cloudpinyin fcitx5-module-lua fcitx5-material-color
    qt5-style-plugins zenity fonts-noto-cjk fonts-noto-color-emoji
    git curl
  )
  for p in "${pkgs[@]}"; do
    ensure_pkg "$p"
  done

  # 2. Determine target user
  local target_user
  if [ -n "${SUDO_USER:-}" ]; then
    target_user="$SUDO_USER"
  else
    target_user="${USER:-$(whoami)}"
  fi
  local target_home
  target_home=$(getent passwd "$target_user" | cut -d: -f6)

  # 3. Download Rime Ice config
  local rime_dir="$target_home/.local/share/fcitx5/rime"
  if [ ! -d "$rime_dir" ]; then
    sudo -u "$target_user" mkdir -p "$rime_dir"
  fi

  # Clone to temp and move, or clone directly if empty
  # Logic adapted from legacy script which clones to tmp and copies
  local tmp_rime="$rime_dir/rime-ice-tmp"
  log_info "Downloading Rime Ice configuration..."
  if [ -d "$tmp_rime" ]; then
      rm -rf "$tmp_rime"
  fi
  
  if sudo -u "$target_user" git clone --depth=1 https://github.com/cogitate3/rime-ice "$tmp_rime"; then
      log_info "Applying Rime configuration..."
      sudo -u "$target_user" cp -r "$tmp_rime"/* "$rime_dir/"
      rm -rf "$tmp_rime"
  else
      log_err "Failed to clone rime-ice repository"
      return 1
  fi

  # 4. Configure Environment Variables
  # Setup ~/.config/environment.d/fcitx5.conf
  local env_dir="$target_home/.config/environment.d"
  if [ ! -d "$env_dir" ]; then
    sudo -u "$target_user" mkdir -p "$env_dir"
  fi
  
  local env_file="$env_dir/fcitx5.conf"
  cat <<EOF | sudo -u "$target_user" tee "$env_file" >/dev/null
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
SDL_IM_MODULE=fcitx
EOF

  # Also add to .profile for compatibility
  local profile="$target_home/.profile"
  if ! grep -q "GTK_IM_MODULE=fcitx" "$profile"; then
      cat <<EOF | sudo -u "$target_user" tee -a "$profile" >/dev/null

# Fcitx5 input method
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx
export SDL_IM_MODULE=fcitx
EOF
  fi

  # 5. Configure Autostart
  # We can use the autostart module logic if we import it, or just write the file.
  # Writing directly for simplicity and independence.
  local autostart_dir="$target_home/.config/autostart"
  if [ ! -d "$autostart_dir" ]; then
      sudo -u "$target_user" mkdir -p "$autostart_dir"
  fi
  
  cat <<EOF | sudo -u "$target_user" tee "$autostart_dir/fcitx5.desktop" >/dev/null
[Desktop Entry]
Name=Fcitx 5
Name[zh_CN]=Fcitx 5 输入法
Comment=Start Input Method
Exec=fcitx5
Icon=fcitx
Terminal=false
Type=Application
Categories=System;Utility;
StartupNotify=false
X-GNOME-Autostart-Phase=Applications
EOF

  log_info "Rime setup complete. Please restart your session."
}
register_module
