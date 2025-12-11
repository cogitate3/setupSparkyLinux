MOD_ID="flatpak"
MOD_NAME="Flatpak Package Manager"
MOD_DESC="Installs Flatpak and adds Flathub repository."
MOD_GROUP="System"

mod_check() {
  if command -v flatpak >/dev/null 2>&1; then
      return 0
  fi
  return 1
}

mod_install() {
  # 1. Install Flatpak
  ensure_pkg "flatpak"

  # 2. Desktop Environment Integration
  # Detect DE logic similar to legacy script
  local de=""
  if [ -n "$XDG_CURRENT_DESKTOP" ]; then
    de=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')
  elif [ -n "$DESKTOP_SESSION" ]; then
    de=$(echo "$DESKTOP_SESSION" | tr '[:upper:]' '[:lower:]')
  fi

  if [[ "$de" == *"gnome"* ]]; then
      log_info "Installing GNOME Software Flatpak plugin..."
      ensure_pkg "gnome-software-plugin-flatpak"
  elif [[ "$de" == *"kde"* || "$de" == *"plasma"* ]]; then
      log_info "Installing KDE Plasma Discover Flatpak backend..."
      ensure_pkg "plasma-discover-backend-flatpak"
  else
      log_info "No specific Flatpak plugin found for DE: $de"
  fi

  # 3. Add Flathub Remote
  log_cmd "Adding Flathub repository" flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

register_module
