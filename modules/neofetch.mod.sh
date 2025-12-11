MOD_ID="neofetch"
MOD_NAME="Neofetch"
MOD_DESC="A command-line system information tool."
MOD_GROUP="CLI Tools"

mod_check() {
  command -v neofetch >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "neofetch"
}

register_module
