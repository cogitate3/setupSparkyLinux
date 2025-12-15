MOD_ID="rime"
MOD_NAME="Rime Input Method (Fcitx5)"
MOD_DESC="Rime input method engine for Fcitx5 (with Rime Ice / 雾凇拼音)."
MOD_GROUP="Input Method"

mod_check() {
  # Check if package is installed AND configuration exists
  if check_pkg_installed "fcitx5-rime"; then
      # Also check if we have configured it (e.g. profile exists)
      local target_user="${SUDO_USER:-$USER}"
      local target_home=$(getent passwd "$target_user" | cut -d: -f6)
      if [ -f "$target_home/.config/fcitx5/profile" ]; then
          return 0
      fi
  fi
  return 1
}

_configure_env() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  
  log_info "Configuring Environment Variables..."
  
  # 0. Use im-config if available (Debian standard)
  if command -v im-config >/dev/null 2>&1; then
      log_info "Using im-config to set fcitx5 as default..."
      # -n sets the input method configuration non-interactively
      sudo -u "$target_user" im-config -n fcitx5
  fi

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


_remove_conflicts() {
  log_info "Removing conflicting input methods (ibus, fcitx4)..."
  # We use apt-get remove to avoid removing deps we might want, but legacy used remove.
  # Legacy: apt remove -y ibus ibus-* fcitx*
  # We should be careful not to fail if they aren't installed.
  sudo apt-get remove -y ibus "ibus-*" "fcitx*" >/dev/null 2>&1 || true
  sudo apt-get autoremove -y >/dev/null 2>&1 || true
}

_configure_fcitx() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  
  # Ensure Fcitx5 is NOT running, otherwise it will overwrite our config on exit
  if pgrep -u "$target_user" fcitx5 >/dev/null; then
    log_info "Stopping running Fcitx5 process to apply configurations..."
    killall -u "$target_user" fcitx5 >/dev/null 2>&1 || true
    sleep 2
  fi
  
  local conf_dir="$target_home/.config/fcitx5"
  local data_dir="$target_home/.local/share/fcitx5"

  mkdir -p "$conf_dir/conf"
  mkdir -p "$data_dir/themes"
  
  # Configure Profile
  cat > "$conf_dir/profile" <<EOF
[Groups/0]
# Group Name
Name=Default
# Layout
Default Layout=us
# Default Input Method
DefaultIM=rime

[Groups/0/Items/0]
# Name
Name=keyboard-us
# Layout
Layout=

[Groups/0/Items/1]
# Name
Name=rime
# Layout
Layout=

[GroupOrder]
0=Default
EOF

  # Configure Global Config
  cat > "$conf_dir/config" <<EOF
[Hotkey]
# Enumerate when press trigger key repeatedly
EnumerateWithTriggerKeys=True
# Temporally switch between first and current Input Method
AltTriggerKeys=
# Enumerate Input Method Forward
EnumerateForwardKeys=
# Enumerate Input Method Backward
EnumerateBackwardKeys=
# Skip first input method while enumerating
EnumerateSkipFirst=False

[Hotkey/TriggerKeys]
0=Control+space

[Hotkey/EnumerateGroupForwardKeys]
0=Super+space

[Hotkey/EnumerateGroupBackwardKeys]
0=Shift+Super+space

[Hotkey/ActivateKeys]
0=Hangul_Hanja

[Hotkey/DeactivateKeys]
0=Hangul_Romaja

[Hotkey/PrevPage]
0=Up

[Hotkey/NextPage]
0=Down

[Hotkey/PrevCandidate]
0=Shift+Tab

[Hotkey/NextCandidate]
0=Tab

[Hotkey/TogglePreedit]
0=Control+Alt+P

[Behavior]
# Active By Default
ActiveByDefault=True
# Share Input State
ShareInputState=No
# Show preedit in application
PreeditEnabledByDefault=True
# Show Input Method Information when switch input method
ShowInputMethodInformation=True
# Show Input Method Information when changing focus
showInputMethodInformationWhenFocusIn=False
# Show compact input method information
CompactInputMethodInformation=True
# Show first input method information
ShowFirstInputMethodInformation=True
# Default page size
DefaultPageSize=7
# Override Xkb Option
OverrideXkbOption=False
# Custom Xkb Option
CustomXkbOption=
# Force Enabled Addons
EnabledAddons=
# Force Disabled Addons
DisabledAddons=
# Preload input method to be used by default
PreloadInputMethod=True
EOF

  # Configure Classic UI
  cat > "$conf_dir/conf/classicui.conf" <<EOF
# Vertical Candidate List
Vertical Candidate List=False
# Use mouse wheel to go to prev or next page
WheelForPaging=True
# Font
Font="Noto Sans CJK SC 11"
# Menu Font
MenuFont="Sans 10"
# Tray Font
TrayFont="Sans Bold 10"
# Tray Label Outline Color
TrayOutlineColor=#000000
# Tray Label Text Color
TrayTextColor=#ffffff
# Prefer Text Icon
PreferTextIcon=False
# Show Layout Name In Icon
ShowLayoutNameInIcon=True
# Use input method language to display text
UseInputMethodLanguageToDisplayText=True
# Theme
Theme=Material-Color-orange
# Dark Theme
DarkTheme=Material-Color-deepPurple
# Follow system light/dark color scheme
UseDarkTheme=False
# Follow system accent color if it is supported by theme and desktop
UseAccentColor=True
# Use Per Screen DPI on X11
PerScreenDPI=True
# Force font DPI on Wayland
ForceWaylandDPI=0
# Enable fractional scale under Wayland
EnableFractionalScale=True
EOF

  # Configure Cloud Pinyin
  cat > "$conf_dir/conf/cloudpinyin.conf" <<EOF
# 云拼音来源
CloudPinyinBackend=Baidu
# 最小拼音长度
MinimumPinyinLength=2
EOF

  # Configure Punctuation
  cat > "$conf_dir/conf/punctuation.conf" <<EOF
# 半角/全角标点切换
HalfWidthPuncAfterLetterOrNumber=True
EOF

  # Configure Rime
  cat > "$conf_dir/conf/rime.conf" <<EOF
# 同步设置
PreeditInApplication=True
# 在程序中显示预编辑文本
PreeditInApplication=True
# 是否允许扩展编辑器
AllowExtensionEditor=False
EOF

  chown -R "$target_user:$target_user" "$conf_dir"
  chown -R "$target_user:$target_user" "$data_dir"
}

_install_rime_ice() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  local rime_dir="$target_home/.local/share/fcitx5/rime"
  
  log_info "Installing Rime-Ice (雾凇拼音)..."
  ensure_cmd git
  
  # Ensure destination exists
  mkdir -p "$rime_dir"
  
  # Clone to tmp
  local tmp_dir="/tmp/rime-ice-install"
  rm -rf "$tmp_dir"
  git clone --depth 1 "https://github.com/cogitate3/rime-ice" "$tmp_dir"
  
  # Copy to destination (Overlay logic from 902rime_setup.sh)
  log_info "Copying Rime-Ice configurations..."
  cp -r "$tmp_dir"/* "$rime_dir/"
  rm -rf "$tmp_dir"
  
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
  _remove_conflicts

  log_info "Installing Fcitx5 packages..."
  ensure_pkg "fcitx5" \
             "fcitx5-rime" \
             "fcitx5-chinese-addons" \
             "fcitx5-frontend-gtk2" \
             "fcitx5-frontend-gtk3" \
             "fcitx5-frontend-qt5" \
             "fcitx5-module-cloudpinyin" \
             "qt5-style-plugins" \
             "zenity" \
             "fcitx5-module-lua" \
             "fcitx5-material-color" \
             "fonts-noto-cjk" \
             "fonts-noto-color-emoji" \
             "git" \
             "curl" \
             "im-config"

  _configure_env
  _configure_fcitx
  _install_rime_ice
  _configure_autostart
  
  log_info "Rime (Fcitx5+Ice) installation complete."
  log_warn "Please RESTART your session (logout/login) for changes to take effect."
}

mod_uninstall() {
  log_info "Uninstalling Rime..."
  sudo apt-get purge -y fcitx5 \
                        fcitx5-rime \
                        fcitx5-chinese-addons \
                        fcitx5-frontend-gtk2 \
                        fcitx5-frontend-gtk3 \
                        fcitx5-frontend-qt5 \
                        fcitx5-module-cloudpinyin \
                        qt5-style-plugins \
                        fcitx5-module-lua \
                        fcitx5-material-color
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
