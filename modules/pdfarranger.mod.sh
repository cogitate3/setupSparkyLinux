MOD_ID="pdfarranger"
MOD_NAME="PDF Arranger"
MOD_DESC="A tool to rearrange and modify PDF files."
MOD_GROUP="Multimedia"

mod_check() {
  if command -v pdfarranger >/dev/null 2>&1; then return 0; fi
  if [ -x "$HOME/.local/bin/pdfarranger" ]; then return 0; fi
  return 1
}

mod_install() {
  # 1. Install System Dependencies
  # List taken from legacy/903new_after.sh
  log_info "Installing system dependencies..."
  ensure_pkg "python3-pip" "python3-wheel" "python3-gi" "python3-gi-cairo" \
             "gir1.2-gtk-3.0" "gir1.2-poppler-0.18" "gir1.2-handy-1" "python3-setuptools" \
             "gir1.2-gdkpixbuf-2.0" "pkg-config" "libcairo2-dev" "libgirepository1.0-dev"

  # 2. Install pipx
  ensure_pkg "pipx"
  log_cmd "Ensuring pipx path" pipx ensurepath

  # 3. Install pdfarranger via pipx
  # Legacy script installed from github zipball. We can stick to that or pip.
  # "pipx install https://github.com/pdfarranger/pdfarranger/zipball/main"
  
  local target_user="${SUDO_USER:-$USER}"
  
  log_info "Installing pdfarranger via pipx as user $target_user..."
  sudo -u "$target_user" pipx install https://github.com/pdfarranger/pdfarranger/zipball/main
  
  # 4. Inject dependencies if needed (pygobject)
  sudo -u "$target_user" pipx inject pdfarranger pygobject
}

register_module
