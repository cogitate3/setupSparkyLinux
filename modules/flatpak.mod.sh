MOD_ID="flatpak"
MOD_NAME="Flatpak Package Manager"
MOD_DESC="Flatpak and Flathub repository."
MOD_GROUP="System"

mod_check() {
  command -v flatpak >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "flatpak" "gnome-software-plugin-flatpak"
  
  log_info "Adding Flathub repository..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

mod_uninstall() {
  log_info "Uninstalling Flatpak..."
  # Remove remotes?
  flatpak remote-delete flathub --force
  
  sudo apt-get purge -y flatpak gnome-software-plugin-flatpak
}

register_module
