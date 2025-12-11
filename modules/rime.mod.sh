MOD_ID="rime"
MOD_NAME="Rime Input Method (Fcitx5)"
MOD_DESC="Rime input method engine for Fcitx5."
MOD_GROUP="Input Method"

mod_check() {
  check_pkg_installed "fcitx5-rime"
}

mod_install() {
  ensure_pkg "fcitx5" "fcitx5-rime" "im-config"
  
  # Configure im-config?
  # im-config -n fcitx5
  
  # Install plum (rime config manager) if needed?
  # Legacy script did a lot of rime config.
  # We'll stick to basics + cloning rime-ice if requested.
}

mod_uninstall() {
  log_info "Uninstalling Rime..."
  sudo apt-get purge -y fcitx5 fcitx5-rime
  sudo apt-get autoremove -y
}

register_module
