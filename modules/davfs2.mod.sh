MOD_ID="davfs2"
MOD_NAME="WebDAV (davfs2)"
MOD_DESC="Mount WebDAV shares."
MOD_GROUP="Network & Storage"

mod_check() {
  check_pkg_installed "davfs2"
}

mod_install() {
  ensure_pkg "davfs2"
  
  # Permission setup
  local target_user="${SUDO_USER:-$USER}"
  log_info "Adding $target_user to davfs2 group..."
  sudo usermod -aG davfs2 "$target_user"
  sudo chmod u+s /usr/sbin/mount.davfs

  # Interactive Configuration
  if [ "${DRY_RUN:-0}" -ne 1 ]; then
      echo ""
      print_cyan "--- WebDAV Configuration ---"
      read -p "Do you want to configure a WebDAV mount now? (y/N) " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Yy]$ ]]; then
          read -p "Enter WebDAV URL (e.g., https://webdav.example.com): " dav_url
          read -p "Enter Username: " dav_user
          read -s -p "Enter Password: " dav_pass
          echo ""
          read -p "Enter Mount Point (default: /mnt/webdav): " mount_point
          mount_point="${mount_point:-/mnt/webdav}"

          # Create mount point
          if [ ! -d "$mount_point" ]; then
              log_cmd "Creating mount point $mount_point" sudo mkdir -p "$mount_point"
              sudo chown "$target_user:$target_user" "$mount_point"
          fi

          # Add to secrets
          local secrets_file="/etc/davfs2/secrets"
          if grep -qF "$dav_url" "$secrets_file"; then
              log_warn "URL already in $secrets_file. Skipping secrets update."
          else
              log_cmd "Adding credentials to $secrets_file" sudo sh -c "echo '$dav_url $dav_user $dav_pass' >> $secrets_file"
              sudo chmod 600 "$secrets_file"
          fi

          # Add to fstab
          local fstab_entry="$dav_url $mount_point davfs user,rw,auto 0 0"
          if grep -qF "$dav_url" /etc/fstab; then
              log_warn "Entry for $dav_url already exists in /etc/fstab."
          else
              log_cmd "Adding to /etc/fstab" sudo sh -c "echo '$fstab_entry' >> /etc/fstab"
          fi
          
          log_info "Configuration complete. You may need to relogin for group changes to take effect."
          log_info "Try mounting with: mount $mount_point"
      fi
  fi
}

mod_uninstall() {
  log_info "Uninstalling Davfs2..."
  sudo apt-get purge -y davfs2
  log_warn "Note: /etc/davfs2/secrets and /etc/fstab were NOT modified. Please clean them manually if needed."
}

register_module
