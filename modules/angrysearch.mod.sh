MOD_ID="angrysearch"
MOD_NAME="AngrySearch"
MOD_DESC="Linux file search, instant results as you type."
MOD_GROUP="Desktop Apps"

mod_check() {
  if [ -d "/usr/share/angrysearch" ]; then return 0; fi
  return 1
}

mod_status() {
  local repo="DoTheEvo/ANGRYsearch"
  local v_local="unknown"
  if [ -f "/usr/share/angrysearch/.version" ]; then
    v_local=$(cat "/usr/share/angrysearch/.version")
  fi
  
  local v_remote_tag=$(gh_get_latest_tag "$repo")
  local v_remote="${v_remote_tag#v}"
  
  echo "$v_local|$v_remote"
  
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "python3-pyqt5" "xdg-utils" "wget"

  local repo="DoTheEvo/ANGRYsearch"
  local tag=$(gh_get_latest_tag "$repo")
  local v_remote="${tag#v}"

  local url
  # Attempt to get binary asset first
  url=$(gh_latest_asset_url "$repo" "\.tar\.gz$" 2>/dev/null || true)
  
  if [ -z "$url" ]; then
    log_info "No binary asset found, falling back to source tag..."
    url="https://github.com/$repo/archive/refs/tags/${tag}.tar.gz"
  fi

  local tmp_dir="/tmp/angrysearch_install"
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"
  local dest="$tmp_dir/angrysearch.tar.gz"
  
  download_file "$url" "$dest"
  
  log_info "Extracting..."
  tar -xzf "$dest" -C "$tmp_dir"
  
  local extracted_dir
  # Find the directory (GitHub tag archives usually use RepoName-Version)
  extracted_dir=$(find "$tmp_dir" -maxdepth 1 -type d ! -path "$tmp_dir" | head -n 1)
  
  if [ -n "$extracted_dir" ] && [ -d "$extracted_dir" ]; then
    local start_dir="$PWD"
    cd "$extracted_dir"
    log_info "Running install script in $extracted_dir..."
    log_cmd "Installing AngrySearch" sudo ./install.sh
    echo "$v_remote" | sudo tee /usr/share/angrysearch/.version > /dev/null
    cd "$start_dir"
  else
    log_err "Failed to find extracted directory in $tmp_dir"
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
