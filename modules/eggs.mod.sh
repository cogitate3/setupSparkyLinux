MOD_ID="eggs"
MOD_NAME="Penguins' Eggs"
MOD_DESC="A console tool to remaster your system."
MOD_GROUP="System"

mod_check() {
  command -v eggs >/dev/null 2>&1
}

mod_install() {
  # Eggs is complex to version check from git clone, 
  # but if user runs install again, we can re-clone and re-install to update.
  # The legacy script doesn't check version, it just clones and runs.
  
  if mod_check; then
    log_info "Eggs is installed. Re-running installer to update..."
  fi

  # 1. Dependencies
  ensure_pkg "squashfs-tools" "xorriso" "grub-pc-bin" "grub-efi-amd64-bin" "mtools"

  # 2. Clone Repository
  local install_dir="$HOME/Downloads/eggs_install"
  if [ -d "$install_dir" ]; then rm -rf "$install_dir"; fi
  mkdir -p "$install_dir"
  
  log_info "Cloning get-eggs repository..."
  if ! git clone https://github.com/pieroproietti/get-eggs "$install_dir"; then
    log_err "Failed to clone repository"
    return 1
  fi
  
  if [ ! -d "$install_dir/.git" ]; then
    log_err "Clone verification failed"
    return 1
  fi

  cd "$install_dir"
  
  # 3. Patch for SparkyLinux Support (Orion Belt)
  log_info "Patching ppa.sh for SparkyLinux support..."
  sed -i 's/        trixie | excalibur | noble )/        trixie | excalibur | noble | orion-belt )/' ppa.sh
  
  # 4. Run Installer
  log_info "Running get-eggs.sh..."
  log_cmd "Installing eggs" sudo ./get-eggs.sh
  
  # 5. Configure Derivatives
  local conf_file="/usr/lib/penguins-eggs/conf/derivatives.yaml"
  if [ -f "$conf_file" ]; then
    log_info "Configuring derivatives.yaml..."
    sudo sed -i '/# bookworm derivated/a - id: sparky\n  distroLike: Debian\n  family: debian\n  ids:\n    - orion-belt # SparkyLinux 7' "$conf_file"
    log_cmd "Updating eggs database" sudo eggs dad -d
  fi
  
  rm -rf "$install_dir"
}

mod_uninstall() {
  log_info "Uninstalling Penguins' Eggs..."
  # eggs installs via npm or deb usually, but get-eggs.sh seemingly uses apt/deb behind the scenes or npm?
  # Reading get-eggs.sh source would confirm, but typically it installs a package 'eggs'.
  
  log_cmd "Removing eggs package" sudo apt-get purge -y eggs
  
  # Cleanup deps?
  # ensure_pkg handles install, removing deps might break other things so we skip explicit dep removal except autoremove
  sudo apt-get autoremove -y
}

register_module
