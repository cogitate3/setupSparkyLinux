MOD_ID="davfs2"
MOD_NAME="WebDAV (davfs2)"
MOD_DESC="Installs davfs2 for mounting WebDAV shares and configures user permissions."
MOD_GROUP="Network & Storage"

mod_check() {
  command -v mount.davfs >/dev/null 2>&1
}

mod_install() {
  ensure_pkg davfs2

  # Determine target user
  local target_user
  if [ -n "${SUDO_USER:-}" ]; then
    target_user="$SUDO_USER"
  else
    target_user="${USER:-$(whoami)}"
  fi

  # Add user to davfs2 group
  log_info "Adding $target_user to davfs2 group..."
  usermod -aG davfs2 "$target_user"

  # Create secrets file
  local user_home
  user_home=$(getent passwd "$target_user" | cut -d: -f6)
  local secrets_dir="$user_home/.davfs2"
  local secrets_file="$secrets_dir/secrets"

  if [ ! -d "$secrets_dir" ]; then
    mkdir -p "$secrets_dir"
    chown "$target_user:$(id -gn "$target_user")" "$secrets_dir"
    chmod 700 "$secrets_dir"
  fi

  if [ ! -f "$secrets_file" ]; then
    log_info "Creating empty secrets file at $secrets_file"
    touch "$secrets_file"
    chown "$target_user:$(id -gn "$target_user")" "$secrets_file"
    chmod 600 "$secrets_file"
    echo "# usage: /mnt/dav <username> <password>" > "$secrets_file"
  else
    log_info "Secrets file already exists at $secrets_file"
  fi
}
register_module
