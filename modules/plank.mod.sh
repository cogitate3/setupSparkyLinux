MOD_ID="plank"
MOD_NAME="Plank Dock"
MOD_DESC="Installs Plank dock and dependencies."
MOD_GROUP="Appearance"

mod_check() {
  if command -v plank >/dev/null 2>&1; then
      return 0
  fi
  return 1
}

mod_install() {
  # 1. Install Dependencies
  # Legacy script included some fonts, we'll ensure them here too just in case 'fonts' module isn't run.
  local pkgs=(
    curl
    fonts-wqy-zenhei
    fonts-noto-cjk
    fonts-wqy-microhei
    xfonts-wqy
    plank
  )
  for p in "${pkgs[@]}"; do
    ensure_pkg "$p"
  done
  
  # 2. Setup Autostart (Optional, but good practice for a Dock)
  # We use the 'autostart' module's checking logic? No, let's keep it self-contained or use the generic autostart file creation.
  
  local target_user="${SUDO_USER:-$USER}"
  local target_home
  target_home=$(getent passwd "$target_user" | cut -d: -f6)
  local autostart_dir="$target_home/.config/autostart"
  
  if [ ! -d "$autostart_dir" ]; then
    sudo -u "$target_user" mkdir -p "$autostart_dir"
  fi

  cat <<EOF | sudo -u "$target_user" tee "$autostart_dir/plank.desktop" >/dev/null
[Desktop Entry]
Name=Plank
Comment=Stupidly simple.
Exec=plank
Icon=plank
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=false
X-GNOME-Autostart-Phase=Applications
EOF
  
  log_info "Plank installed and configured to autostart."
}

register_module
