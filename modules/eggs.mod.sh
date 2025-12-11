MOD_ID="eggs"
MOD_NAME="Penguins' Eggs"
MOD_DESC="A console tool to remaster your system."
MOD_GROUP="System"

mod_check() {
  command -v eggs >/dev/null 2>&1
}

mod_install() {
  # 1. Dependencies
  ensure_pkg "squashfs-tools" "xorriso" "grub-pc-bin" "grub-efi-amd64-bin" "mtools"

  # 2. Clone Repository
  local install_dir="$HOME/Downloads/eggs_install"
  if [ -d "$install_dir" ]; then rm -rf "$install_dir"; fi
  mkdir -p "$install_dir"
  
  log_info "Cloning get-eggs repository..."
  # Retry loop logic simplified
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
  # Legacy logic: adds "orion-belt" to the list of supported distros in ppa.sh
  log_info "Patching ppa.sh for SparkyLinux support..."
  sed -i 's/        trixie | excalibur | noble )/        trixie | excalibur | noble | orion-belt )/' ppa.sh
  
  # 4. Run Installer
  log_info "Running get-eggs.sh..."
  log_cmd "Installing eggs" sudo ./get-eggs.sh
  
  # 5. Configure Derivatives
  local conf_file="/usr/lib/penguins-eggs/conf/derivatives.yaml"
  if [ -f "$conf_file" ]; then
    log_info "Configuring derivatives.yaml..."
    # Warning: simpler sed than legacy to avoid multi-line complexity if possible, 
    # but sticking to legacy logic for safety.
    # Legacy:
    # sudo sed -i '/# bookworm derivated/a - id: sparky\n  distroLike: Debian\n  family: debian\n  ids:\n    - orion-belt # SparkyLinux 7' /usr/lib/penguins-eggs/conf/derivatives.yaml
    
    # We'll write a small helper script to do this injection carefully or use a proper temp file.
    # NOTE: sudo sed -i works fine.
    
    sudo sed -i '/# bookworm derivated/a - id: sparky\n  distroLike: Debian\n  family: debian\n  ids:\n    - orion-belt # SparkyLinux 7' "$conf_file"
    
    log_cmd "Updating eggs database" sudo eggs dad -d
  else
    log_warn "derivatives.yaml not found, skipping configuration."
  fi
  
  rm -rf "$install_dir"
}

register_module
