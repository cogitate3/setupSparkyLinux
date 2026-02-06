MOD_ID="windsurf"
MOD_NAME="Windsurf IDE"
MOD_DESC="An AI-powered Code Editor."
MOD_GROUP="Dev Tools"

mod_check() {
  command -v windsurf >/dev/null 2>&1
}

mod_status() {
  local v_local=$(get_pkg_version "windsurf")
  local v_remote=$(apt-cache policy "windsurf" 2>/dev/null | grep "Candidate:" | awk '{print $2}' | sed 's/^[0-9]*://')
  [ -z "$v_remote" ] && v_remote="latest"
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  [ "$v_remote" = "latest" ] && return 0
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  ensure_pkg "curl" "gnupg"

  if [ ! -f /etc/apt/sources.list.d/windsurf.list ]; then
    log_info "Adding Windsurf GPG key..."
    curl -fsSL "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" < /dev/null | \
      log_cmd "Saving GPG key" sudo gpg --dearmor --yes -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg

    log_info "Adding Windsurf repository..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | \
      log_cmd "Writing sources list" sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null

    log_cmd "Updating apt" sudo apt-get update < /dev/null
  fi
  
  ensure_pkg "windsurf"
}

mod_uninstall() {
  log_info "Uninstalling Windsurf..."
  log_cmd "Purging windsurf" sudo apt-get purge -y windsurf < /dev/null
  
  log_info "Removing repository..."
  sudo rm -f /etc/apt/sources.list.d/windsurf.list
  sudo rm -f /usr/share/keyrings/windsurf-stable-archive-keyring.gpg
  
  log_cmd "Updating apt" sudo apt-get update < /dev/null
}

register_module
