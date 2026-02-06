MOD_ID="vlc"
MOD_NAME="VLC Media Player"
MOD_DESC="The versatile media player."
MOD_GROUP="Multimedia"

mod_check() {
  command -v vlc >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "vlc")
  local v_remote=$(apt-cache policy "vlc" | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "vlc"
}

mod_uninstall() {
  log_info "Uninstalling VLC..."
  log_cmd "Purging vlc" sudo apt-get purge -y vlc < /dev/null
}

register_module
