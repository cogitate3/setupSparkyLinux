MOD_ID="spacefm"
MOD_NAME="SpaceFM"
MOD_DESC="A multi-panel tabbed file manager."
MOD_GROUP="System"

mod_check() {
  command -v spacefm >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "spacefm"
}

register_module
