MOD_ID="micro"
MOD_NAME="Micro Editor"
MOD_DESC="A modern and intuitive terminal-based text editor."
MOD_GROUP="CLI Tools"

mod_check() {
  command -v micro >/dev/null 2>&1
}

mod_status() {
  local repo="zyedidia/micro"
  local v_local=$(micro --version | grep -oP 'Version: \K[0-9.]+' || echo "unknown")
  local v_remote_tag=$(gh_get_latest_tag "$repo")
  local v_remote="${v_remote_tag#v}"
  
  echo "$v_local|$v_remote"
  
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  local repo="zyedidia/micro"

  log_info "Finding latest asset for $repo..."
  local url
  url=$(gh_latest_asset_url "$repo" ".*linux64\.tar\.gz$")
  
  if [ -z "$url" ]; then
    log_err "Could not find asset for $repo"
    return 1
  fi
  
  local tmp_dir="/tmp/micro_install"
  mkdir -p "$tmp_dir"
  local dest="$tmp_dir/micro.tar.gz"
  
  log_stream "Downloading Micro" curl -L -o "$dest" "$url" < /dev/null
  
  log_info "Extracting..."
  tar -xzf "$dest" -C "$tmp_dir"
  
  local binary_path
  binary_path=$(find "$tmp_dir" -name "micro" -type f | head -n 1)
  
  if [ -f "$binary_path" ]; then
    log_info "Installing binary to /usr/local/bin..."
    log_cmd "Installing micro" sudo install -m 755 "$binary_path" /usr/local/bin/micro
  else
    log_err "Could not find micro binary in extracted files."
    return 1
  fi
  
  rm -rf "$tmp_dir"
}

mod_uninstall() {
  log_info "Uninstalling Micro..."
  if [ -f "/usr/local/bin/micro" ]; then
    log_cmd "Removing binary" sudo rm -f "/usr/local/bin/micro"
  fi
  
  # Clean config?
  # log_info "Removing config..."
  # rm -rf ~/.config/micro
}

register_module
