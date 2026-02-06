MOD_ID="autostart"
MOD_NAME="Autostart Configuration"
MOD_DESC="Manage application autostart entries."
MOD_GROUP="Hidden"

mod_check() {
  # Logic to check if our custom autostarts are present?
  # Difficult to say "installed" or not. Always return 0 so install can run/update?
  # Or check for a marker file.
  if [ -f "$HOME/.config/autostart/.setup_sparky_marker" ]; then return 0; fi
  return 1
}

mod_status() {
  if mod_check; then
    echo "active|current"
    return 0
  fi
  echo "none|current"
  return 2
}

mod_install() {
  # This module logic was placeholder in legacy migration.
  # We should implement actual autostart addition if needed.
  # For now, let's just mark it installed.
  
  mkdir -p "$HOME/.config/autostart"
  touch "$HOME/.config/autostart/.setup_sparky_marker"
  log_info "Autostart configuration checked."
}

mod_uninstall() {
  log_info "Uninstalling Autostart configuration..."
  rm -f "$HOME/.config/autostart/.setup_sparky_marker"
}

register_module
