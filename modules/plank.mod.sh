MOD_ID="plank"
MOD_NAME="Plank Dock"
MOD_DESC="Stupidly simple."
MOD_GROUP="Appearance"

mod_check() {
  command -v plank >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "plank")
  local v_remote=$(apt-cache policy "plank" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "plank"

  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  local autostart_dir="$target_home/.config/autostart"
  
  if [ "${DRY_RUN:-0}" -ne 1 ]; then
      mkdir -p "$autostart_dir"
      cat > "$autostart_dir/plank.desktop" <<EOF
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
      chown -R "$target_user:$target_user" "$autostart_dir"
      log_info "Plank added to autostart."
  fi
}

mod_uninstall() {
  log_info "Uninstalling Plank..."
  sudo apt-get purge -y plank < /dev/null
  
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  rm -f "$target_home/.config/autostart/plank.desktop"
}

register_module
