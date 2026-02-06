MOD_ID="pot"
MOD_NAME="Pot Desktop"
MOD_DESC="A cross-platform translator application."
MOD_GROUP="Desktop Apps"

mod_check() {
  command -v pot >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "curl" "libfuse2" # AppImages need FUSE
  
  local repo="pot-app/pot-desktop"
  # Switch to AppImage for better compatibility with Debian Trixie (avoid libwebkit2gtk-4.0 issues)
  local url
  url=$(gh_latest_asset_url "$repo" ".*amd64.*\.AppImage$")
  
  if [ -z "$url" ]; then
    log_err "Could not find .AppImage asset for $repo."
    return 1
  fi
  
  local install_dir="/opt/pot"
  sudo mkdir -p "$install_dir"
  
  local dest="$install_dir/pot.AppImage"
  download_file "$url" "$dest" || return 1
  sudo chmod +x "$dest"
  
  # Symlink
  log_cmd "Creating symlink" sudo ln -sf "$dest" "/usr/bin/pot"
  
  # Extract Icon (optional, or just use a generic one? Pot usually packs one)
  # For now, let's fetch a logo or use a placeholder.
  # Better: download logo from github repo if possible.
  local icon_dest="$install_dir/pot.png"
  download_file "https://raw.githubusercontent.com/pot-app/pot-desktop/master/public/icon.png" "$icon_dest" || true
  
  # Desktop Entry
  cat <<EOF | sudo tee /usr/share/applications/pot.desktop >/dev/null
[Desktop Entry]
Name=Pot Desktop
Comment=Cross-platform translator application
Exec=/usr/bin/pot --no-sandbox %F
Icon=$icon_dest
Terminal=false
Type=Application
Categories=Utility;Translation;
StartupWMClass=pot
MimeType=x-scheme-handler/pot;
EOF

  # Save version
  # GH tag is usually vX.Y.Z
  local tag=$(gh_get_latest_tag "$repo")
  echo "${tag#v}" | sudo tee "$install_dir/.version" >/dev/null

  # Source menu helpers for printing
  source lib/menu.sh 2>/dev/null || true

  echo ""
  print_cyan "--- Pot Desktop Installed (AppImage) ---"
  print_green "Location: $dest"
}

mod_uninstall() {
  log_info "Uninstalling Pot Desktop..."
  sudo rm -rf "/opt/pot"
  sudo rm -f "/usr/bin/pot"
  sudo rm -f "/usr/share/applications/pot.desktop"
}

mod_status() {
  local repo="pot-app/pot-desktop"
  local v_local="unknown"
  if [ -f "/opt/pot/.version" ]; then
      v_local=$(cat "/opt/pot/.version")
  fi
  
  local v_remote_tag=$(gh_get_latest_tag "$repo")
  local v_remote="${v_remote_tag#v}"
  
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

register_module
