MOD_ID="sshfs"
MOD_NAME="SSHFS"
MOD_DESC="Installs SSHFS for mounting remote filesystems over SSH."
MOD_GROUP="Network & Storage"

mod_check() {
  command -v sshfs >/dev/null 2>&1
}

mod_install() {
  ensure_pkg sshfs
}
register_module
