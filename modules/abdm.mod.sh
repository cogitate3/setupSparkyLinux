MOD_ID="abdm"
MOD_NAME="AB Download Manager"
MOD_DESC="A modern download manager."
MOD_GROUP="Desktop Apps"

mod_check() {
  if check_pkg_installed "abdownloadmanager"; then return 0; fi
  if [ -x "/opt/abdm/bin/ABDownloadManager" ]; then return 0; fi
  return 1
}

mod_status() {
  local repo="amir1376/ab-download-manager"
  local v_local="unknown"
  
  if check_pkg_installed "abdownloadmanager"; then
    v_local=$(get_pkg_version "abdownloadmanager")
  elif [ -x "/opt/abdm/bin/ABDownloadManager" ]; then
    v_local=$(/opt/abdm/bin/ABDownloadManager --version 2>/dev/null | head -n 1)
  fi
  
  local v_remote_tag=$(gh_get_latest_tag "$repo")
  local v_remote="${v_remote_tag#v}"
  
  echo "$v_local|$v_remote"
  
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "wget" "tar"
  local repo="amir1376/ab-download-manager"
  
  # Version check for debs is already handled by apt/dpkg. 
  # For manual install, we just overwrite for now or check a version file if it exists.

  local url
  url=$(gh_latest_asset_url "$repo" ".*linux_x64.*\.deb$" 0 2>/dev/null || true)
  
  if [ -n "$url" ]; then
    log_info "Found .deb asset, installing via apt..."
    local tmp_deb="/tmp/abdm_install.deb"
    log_stream "Downloading AB Download Manager" curl -L -o "$tmp_deb" "$url" < /dev/null
    log_info "Installing package..."
    ensure_pkg "$tmp_deb"
    rm -f "$tmp_deb"
  else
    # Check for tarball fallback
    local url_tar=$(gh_latest_asset_url "$repo" "linux_x64\.tar\.gz$" 0 2>/dev/null || true)
    
    if [ -n "$url_tar" ]; then
        log_info "No .deb found, attempting .tar.gz installation..."
        local tmp_tar="/tmp/abdm_install.tar.gz"
        log_stream "Downloading AB Download Manager" curl -L -o "$tmp_tar" "$url_tar" < /dev/null
    
    log_info "Extracting to /opt/abdm..."
    local tmp_dir="/tmp/abdm_extract"
    rm -rf "$tmp_dir" && mkdir -p "$tmp_dir"
    
    if [ -f "$tmp_tar" ]; then
        tar -xzf "$tmp_tar" -C "$tmp_dir"
    else
        if [ "${DRY_RUN:-0}" = "1" ]; then
            log_info "DRY-RUN: Extraction skipped (tarball missing)"
            return 0
        fi
        log_err "Tarball file not found: $tmp_tar"
        return 1
    fi
    
    sudo mkdir -p /opt/abdm
    # Sync content
    local extracted_path=$(find "$tmp_dir" -maxdepth 2 -name "bin" -type d | head -n 1)
    if [ -n "$extracted_path" ]; then
        local src_dir=$(dirname "$extracted_path")
        sudo cp -r "$src_dir/"* /opt/abdm/
    else
        log_err "Failed to find application structure in tarball"
        return 1
    fi
    
    log_info "Creating symlink and desktop entry..."
    sudo ln -sf /opt/abdm/bin/ABDownloadManager /usr/bin/abdownloadmanager
    
    # Try to find an icon
    local icon_path=$(find /opt/abdm -name "*.png" -o -name "*.svg" | head -n 1)
    
    cat <<EOF | sudo tee /usr/share/applications/abdownloadmanager.desktop >/dev/null
[Desktop Entry]
Name=AB Download Manager
Comment=A modern download manager
Exec=/usr/bin/abdownloadmanager
Icon=${icon_path:-abdownloadmanager}
Terminal=false
Type=Application
Categories=Network;Utility;
EOF
    
    rm -rf "$tmp_dir" "$tmp_tar"
    log_info "AB Download Manager installed to /opt/abdm"
  else
    log_err "Could not find suitable asset (deb or tar.gz) for $repo"
    return 1
  fi
  fi
}

mod_uninstall() {
  log_info "Uninstalling AB Download Manager..."
  if check_pkg_installed "abdownloadmanager"; then
    log_cmd "Purging abdownloadmanager package" sudo apt-get purge -y abdownloadmanager < /dev/null
  fi
  
  if [ -d "/opt/abdm" ]; then
    log_info "Removing manual installation at /opt/abdm..."
    sudo rm -rf /opt/abdm
    sudo rm -f /usr/bin/abdownloadmanager
    sudo rm -f /usr/share/applications/abdownloadmanager.desktop
  fi
}

register_module
