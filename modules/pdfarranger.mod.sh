MOD_ID="pdfarranger"
MOD_NAME="PDF Arranger"
MOD_DESC="A tool to rearrange and modify PDF files."
MOD_GROUP="Multimedia"

mod_check() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  
  # Check user's local bin first (since we install via pipx there)
  if [ -x "$target_home/.local/bin/pdfarranger" ]; then return 0; fi
  # Fallback to global path
  if command -v pdfarranger >/dev/null 2>&1; then return 0; fi
  return 1
}

mod_status() {
  local target_user="${SUDO_USER:-$USER}"
  local target_home=$(getent passwd "$target_user" | cut -d: -f6)
  local bin="$target_home/.local/bin/pdfarranger"
  
  local v_local="unknown"
  
  if [ -x "$bin" ]; then
    # Run as user to avoid permission issues or env mismatches
    v_local=$(sudo -u "$target_user" "$bin" --version 2>/dev/null | head -n1 | grep -oP 'Arranger-\K[0-9.]+')
  elif command -v pdfarranger >/dev/null 2>&1; then
    v_local=$(pdfarranger --version 2>/dev/null | head -n1 | grep -oP 'Arranger-\K[0-9.]+')
  fi
  
  # Fallback for empty version
  [ -z "$v_local" ] && v_local="unknown"
    
  local v_remote=$(gh_get_latest_tag "pdfarranger/pdfarranger")
  v_remote="${v_remote#v}"
  
  echo "$v_local|$v_remote"
  [ "$v_local" = "unknown" ] && return 2
  version_ge "$v_local" "$v_remote" && return 0
  return 1
}

mod_install() {
  # 1. Install System Dependencies
  log_info "Installing system dependencies..."
  # Added libgirepository-2.0-dev for pygobject build on Trixie
  ensure_pkg "python3-pip" "python3-wheel" "python3-gi" "python3-gi-cairo" \
             "gir1.2-gtk-3.0" "gir1.2-poppler-0.18" "gir1.2-handy-1" "python3-setuptools" \
             "gir1.2-gdkpixbuf-2.0" "pkg-config" "libcairo2-dev" "libgirepository1.0-dev" \
             "libgirepository-2.0-dev" "gettext"

  # 2. Install pipx
  ensure_pkg "pipx"
  
  local target_user="${SUDO_USER:-$USER}"
  
  # Ensure pipx path for the USER, not root
  log_cmd "Ensuring pipx path for $target_user" sudo -u "$target_user" pipx ensurepath

  # 3. Install pdfarranger via pipx
  log_info "Installing pdfarranger via pipx as user $target_user..."
  sudo -u "$target_user" pipx install https://github.com/pdfarranger/pdfarranger/zipball/main --force
  
  # 4. Inject dependencies if needed (pygobject)
  # Force inject to ensure it rebuilds if needed
  sudo -u "$target_user" pipx inject pdfarranger pygobject --force
}

mod_uninstall() {
  local target_user="${SUDO_USER:-$USER}"
  log_info "Uninstalling PDF Arranger..."
  sudo -u "$target_user" pipx uninstall pdfarranger
}

register_module
