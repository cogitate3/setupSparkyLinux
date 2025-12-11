MOD_ID="konsole"
MOD_NAME="Konsole"
MOD_DESC="KDE Terminal Emulator."
MOD_GROUP="System"

mod_check() {
  command -v konsole >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "konsole"
}

register_module
