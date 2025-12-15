MOD_ID="angrysearch"
MOD_NAME="AngrySearch"
MOD_DESC="Linux file search, instant results as you type."
MOD_GROUP="Desktop Apps"

mod_check() {
  if [ -d "/usr/share/angrysearch" ]; then return 0; fi
  return 1
}

mod_install() {
  ensure_pkg "python3-pyqt5" "xdg-utils" "wget"

  local repo="DoTheEvo/ANGRYsearch"
  
  # Version Check
  if mod_check; then
    # AngrySearch doesn't have a reliable --version CLI. 
    # Legacy script checked `dpkg -l` but it's not a deb install, it's a manual install.
    # We can check a file or just always update if user asks.
    log_info "AngrySearch is installed. Re-installing to update..."
  fi

  local url
  url=$(gh_latest_asset_url "$repo" "\.tar\.gz$")
  
  if [ -z "$url" ]; then
    local tag
    tag=$(gh_get_latest_tag "$repo")
    url="https://github.com/$repo/archive/refs/tags/${tag}.tar.gz"
  fi

  local tmp_dir="/tmp/angrysearch_install"
  mkdir -p "$tmp_dir"
  local dest="$tmp_dir/angrysearch.tar.gz"
  
  log_cmd "Downloading AngrySearch" curl -L -o "$dest" "$url"
  
  log_info "Extracting..."
  tar -xzf "$dest" -C "$tmp_dir"
  
  local extracted_dir
  extracted_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name "ANGRYsearch-*" | head -n 1)
  
  if [ -n "$extracted_dir" ]; then
    cd "$extracted_dir"
    log_info "Running install script..."
    log_cmd "Installing AngrySearch" sudo ./install.sh
  else
    log_err "Failed to find extracted directory."
    return 1
  fi
  
  rm -rf "$tmp_dir"
  
  if [ "${DRY_RUN:-0}" -ne 1 ]; then
      local target_user="${SUDO_USER:-$USER}"
      local target_home=$(getent passwd "$target_user" | cut -d: -f6)
      local autostart_dir="$target_home/.config/autostart"
      
      mkdir -p "$autostart_dir"
      cat > "$autostart_dir/angrysearch.desktop" <<EOF
[Desktop Entry]
Name=AngrySearch
Comment=Linux file search, instant results as you type.
Exec=/usr/bin/angrysearch
Icon=angrysearch
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=false
X-GNOME-Autostart-Phase=Applications
EOF
      chown -R "$target_user:$target_user" "$autostart_dir"
      log_info "AngrySearch added to autostart."
  fi
}

mod_uninstall() {
  log_info "Uninstalling AngrySearch..."
  # install.sh doesn't provide uninstall. Manual removal based on analysis.
  # Usually installs to /usr/share/angrysearch, /usr/bin/angrysearch
  
  sudo rm -rf /usr/share/angrysearch
  sudo rm -f /usr/bin/angrysearch
  sudo rm -f /usr/share/applications/angrysearch.desktop
  
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  rm -f "$target_home/.config/autostart/angrysearch.desktop"
  
  log_info "Removed files manually."
}

register_module
