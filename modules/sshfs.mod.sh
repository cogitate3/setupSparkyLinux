MOD_ID="sshfs"
MOD_NAME="SSHFS"
MOD_DESC="Filesystem client based on SSH File Transfer Protocol."
MOD_GROUP="Network & Storage"

mod_check() {
  command -v sshfs >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "sshfs")
  local v_remote=$(apt-cache policy "sshfs" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "sshfs"
  
  local target_user="${SUDO_USER:-$USER}"
  log_info "Adding $target_user to fuse group (if exists)..."
  if getent group fuse >/dev/null; then
    sudo usermod -aG fuse "$target_user"
  fi
}

mod_uninstall() {
  log_info "Uninstalling SSHFS..."
  sudo apt-get purge -y sshfs < /dev/null
}

register_module
