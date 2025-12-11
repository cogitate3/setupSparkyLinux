MOD_ID="autostart"
MOD_NAME="Autostart Configuration"
MOD_DESC="Provides utilities to manage autostart applications in ~/.config/autostart."
MOD_GROUP="System"

detect_desktop_environment() {
    if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
        echo "${XDG_CURRENT_DESKTOP^^}"
        return
    fi
    if [[ -n "$KDE_FULL_SESSION" ]]; then
        echo "KDE"
    elif [[ -n "$GNOME_DESKTOP_SESSION_ID" ]]; then
        echo "GNOME"
    elif [[ -n "$MATE_DESKTOP_SESSION_ID" ]]; then
        echo "MATE"
    elif [[ "$DESKTOP_SESSION" == "xfce" ]]; then
        echo "XFCE"
    else
        echo "UNKNOWN"
    fi
}

add_autostart_app() {
    local display_name="$1"
    local exec_cmd="$2"
    local minimize_flag="$3"
    shift 3
    local exec_args=("$@")

    # Determine target home and user
    local target_user
    if [ -n "${SUDO_USER:-}" ]; then
      target_user="$SUDO_USER"
    else
      target_user="${USER:-$(whoami)}"
    fi
    local target_home
    target_home=$(getent passwd "$target_user" | cut -d: -f6)

    local autostart_dir="${target_home}/.config/autostart"
    local sanitized_name="${display_name// /_}"
    local desktop_file="${autostart_dir}/${sanitized_name}.desktop"

    local current_de
    current_de=$(detect_desktop_environment)

    if [[ -z "$display_name" || -z "$exec_cmd" ]]; then
        log_err "Usage: add_autostart_app <name> <cmd> <minimize:yes|no> [args...]"
        return 1
    fi

    if [ ! -d "$autostart_dir" ]; then
        sudo -u "$target_user" mkdir -p "$autostart_dir"
    fi

    local exec_line="$exec_cmd"
    if [[ "$minimize_flag" == "yes" ]]; then
        case "$current_de" in
            "KDE") exec_args+=("--minimize") ;;
            "GNOME")
                 if command -v gtk-launch >/dev/null 2>&1; then
                    exec_line="gtk-launch $exec_cmd"
                 fi
                 ;;
            *) exec_args+=("--minimize" "--minimized" "-m") ;;
        esac
    fi

    for arg in "${exec_args[@]}"; do
        exec_line+=" \"$arg\""
    done

    # Create .desktop file
    cat <<EOF | sudo -u "$target_user" tee "$desktop_file" >/dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=$display_name
Exec=$exec_line
Comment=Autostart entry for $display_name
Terminal=false
X-GNOME-Autostart-enabled=true
StartupNotify=true
EOF

    if [[ "$current_de" == "KDE" && "$minimize_flag" == "yes" ]]; then
        echo "X-KDE-AutostartMinimized=true" | sudo -u "$target_user" tee -a "$desktop_file" >/dev/null
    fi

    sudo -u "$target_user" chmod +x "$desktop_file"
    log_info "Created autostart entry: $desktop_file"
}

mod_check() {
  # Always available
  return 0
}

mod_install() {
  # Just ensure properties
  local target_user
  if [ -n "${SUDO_USER:-}" ]; then
    target_user="$SUDO_USER"
  else
    target_user="${USER:-$(whoami)}"
  fi
  local target_home
  target_home=$(getent passwd "$target_user" | cut -d: -f6)
  
  if [ ! -d "$target_home/.config/autostart" ]; then
      sudo -u "$target_user" mkdir -p "$target_home/.config/autostart"
  fi
}
register_module
