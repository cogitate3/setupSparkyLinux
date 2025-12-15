MOD_ID="rime"
MOD_NAME="Rime Input Method (Fcitx5)"
MOD_DESC="Rime input method engine for Fcitx5 (with Rime Ice / 雾凇拼音)."
MOD_GROUP="Input Method"

mod_check() {
  check_pkg_installed "fcitx5-rime"
}

_configure_env() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  
  log_info "Configuring Environment Variables..."
  
  # 1. ~/.config/environment.d/fcitx5.conf
  local env_dir="$target_home/.config/environment.d"
  mkdir -p "$env_dir"
  cat > "$env_dir/fcitx5.conf" <<EOF
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
SDL_IM_MODULE=fcitx
EOF
  chown -R "$target_user:$target_user" "$env_dir"

  # 2. ~/.profile (Compatibility)
  local profile_file="$target_home/.profile"
  if [ -f "$profile_file" ]; then
    # Clean old
    sed -i '/^export GTK_IM_MODULE=fcitx/d' "$profile_file"
    sed -i '/^export QT_IM_MODULE=fcitx/d' "$profile_file"
    sed -i '/^export XMODIFIERS=@im=fcitx/d' "$profile_file"
    sed -i '/^export INPUT_METHOD=fcitx/d' "$profile_file"
    sed -i '/^export SDL_IM_MODULE=fcitx/d' "$profile_file"
    sed -i '/# Fcitx5 input method/d' "$profile_file"
    
    # Append new
    cat >> "$profile_file" <<EOF

# Fcitx5 input method
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx
export SDL_IM_MODULE=fcitx
EOF
    chown "$target_user:$target_user" "$profile_file"
  fi
}

_configure_fcitx() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  
  local conf_dir="$target_home/.config/fcitx5"
  mkdir -p "$conf_dir/conf"
  
  # Global Config
  cat > "$conf_dir/config" <<EOF
[Hotkey]
# Trigger Key
0=Control+space
[Hotkey/TriggerKeys]
0=Control+space
[Behavior]
ActiveByDefault=True
PreeditEnabledByDefault=True
EOF

  # Profile (Enable Rime by default)
  cat > "$conf_dir/profile" <<EOF
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=rime
[Groups/0/Items/0]
Name=keyboard-us
Layout=
[Groups/0/Items/1]
Name=rime
Layout=
[GroupOrder]
0=Default
EOF

  # Cloud Pinyin (Baidu)
  cat > "$conf_dir/conf/cloudpinyin.conf" <<EOF
CloudPinyinBackend=Baidu
MinimumPinyinLength=2
EOF

  # Classic UI (Theme)
  cat > "$conf_dir/conf/classicui.conf" <<EOF
Vertical Candidate List=False
WheelForPaging=True
Font="Noto Sans CJK SC 11"
Theme=Material-Color-orange
DarkTheme=Material-Color-deepPurple
EOF

  chown -R "$target_user:$target_user" "$conf_dir"
}

_install_rime_ice() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  local rime_dir="$target_home/.local/share/fcitx5/rime"
  
  log_info "Installing Rime-Ice (雾凇拼音)..."
  ensure_cmd git
  
  if [ -d "$rime_dir" ]; then
      log_info "Backing up existing Rime config..."
      mv "$rime_dir" "${rime_dir}.bak.$(date +%s)"
  fi
  
  # Clone to tmp
  local tmp_dir="/tmp/rime-ice-install"
  rm -rf "$tmp_dir"
  git clone --depth 1 "https://github.com/cogitate3/rime-ice" "$tmp_dir"
  
  # Move to destination
  mkdir -p "$(dirname "$rime_dir")"
  mv "$tmp_dir" "$rime_dir"
  
  chown -R "$target_user:$target_user" "$(dirname "$rime_dir")"
}

_configure_autostart() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  local autostart_dir="$target_home/.config/autostart"
  mkdir -p "$autostart_dir"
  
  cat > "$autostart_dir/fcitx5.desktop" <<EOF
[Desktop Entry]
Name=Fcitx 5
Name[zh_CN]=Fcitx 5 输入法
Exec=fcitx5
Icon=fcitx
Type=Application
Categories=System;Utility;
StartupNotify=false
X-GNOME-Autostart-Phase=Applications
EOF
  
  chown -R "$target_user:$target_user" "$autostart_dir"
}

mod_install() {
  log_info "Installing Fcitx5 packages..."
  ensure_pkg "fcitx5" "fcitx5-rime" "fcitx5-chinese-addons" \
             "fcitx5-frontend-gtk2" "fcitx5-frontend-gtk3" "fcitx5-frontend-qt5" \
             "fcitx5-module-cloudpinyin" "qt5-style-plugins" "fcitx5-module-lua" \
             "fcitx5-material-color" "fonts-noto-cjk" "fonts-noto-color-emoji" \
             "zenity" "git" "curl"

  _configure_env
  _configure_fcitx
  _install_rime_ice
  _configure_autostart
  
  log_info "Rime (Fcitx5+Ice) installation complete."
  log_warn "Please RESTART your session (logout/login) for changes to take effect."
}

mod_uninstall() {
  log_info "Uninstalling Rime..."
  sudo apt-get purge -y fcitx5 fcitx5-rime fcitx5-chinese-addons
  sudo apt-get autoremove -y
  
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  
  log_info "Cleaning up configs..."
  rm -rf "$target_home/.config/fcitx5"
  rm -rf "$target_home/.local/share/fcitx5"
  rm -f "$target_home/.config/autostart/fcitx5.desktop"
  rm -f "$target_home/.config/environment.d/fcitx5.conf"
  
  # Clean .profile
  sed -i '/# Fcitx5 input method/d' "$target_home/.profile"
  sed -i '/^export GTK_IM_MODULE=fcitx/d' "$target_home/.profile"
  sed -i '/^export QT_IM_MODULE=fcitx/d' "$target_home/.profile"
  sed -i '/^export XMODIFIERS=@im=fcitx/d' "$target_home/.profile"
  sed -i '/^export INPUT_METHOD=fcitx/d' "$target_home/.profile"
  sed -i '/^export SDL_IM_MODULE=fcitx/d' "$target_home/.profile"
}

register_module
