MOD_ID="eg"
MOD_NAME="Eg (TLDR Client)"
MOD_DESC="Useful examples at the command line."
MOD_GROUP="CLI Tools"

# Get target user (fallback to SUDO_USER if available)
get_target_user() {
  echo "${SUDO_USER:-$USER}"
}

mod_check() {
  local target_user=$(get_target_user)
  # Check if pipx knows about 'eg'
  if sudo -u "$target_user" pipx list --short 2>/dev/null | grep -q "^eg "; then
     return 0
  fi
  # Fallback: check if binary exists in typical user path
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  if [ -x "$target_home/.local/bin/eg" ]; then
     return 0
  fi
  return 1
}

mod_status() {
  local v_local="unknown"
  local v_remote="unknown"
  local target_user=$(get_target_user)

  # Get local version from pipx (user scope)
  # Output format of `pipx list`: "package eg 1.2.3, installed..."
  # Output format of `pipx list --short`: "eg 1.2.3"
  if command -v pipx >/dev/null 2>&1; then
      local info
      info=$(sudo -u "$target_user" pipx list 2>/dev/null | grep "package eg")
      if [ -n "$info" ]; then
          v_local=$(echo "$info" | awk '{print $3}' | sed 's/,$//')
      fi
  fi

  # Get remote version from PyPI
  local pypi_json
  pypi_json=$(curl -s "https://pypi.org/pypi/eg/json" < /dev/null)
  
  if [ -n "$pypi_json" ]; then
      v_remote=$(echo "$pypi_json" | grep -o '"version":"[^"]*"' | head -n 1 | cut -d'"' -f4)
  fi
  
  [ -z "$v_remote" ] && v_remote="latest"

  echo "$v_local|$v_remote"

  [ "$v_local" = "unknown" ] && return 2
  
  if [ "$v_remote" != "latest" ] && [ "$v_remote" != "unknown" ]; then
      version_ge "$v_local" "$v_remote" && return 0
      return 1
  fi
  
  return 0
}

mod_install() {
  ensure_pkg "python3-full" "python3-pip" "pipx"
  
  local target_user=$(get_target_user)
  
  if mod_check; then
     log_info "Eg is installed. Attempting upgrade..."
     sudo -u "$target_user" pipx upgrade eg
  else
     log_info "Installing 'eg' via pipx for user $target_user..."
     sudo -u "$target_user" pipx install eg
     
     # Ensure path is added
     sudo -u "$target_user" pipx ensurepath
  fi
}

mod_uninstall() {
  local target_user=$(get_target_user)
  log_info "Uninstalling Eg via pipx..."
  sudo -u "$target_user" pipx uninstall eg
}

register_module
