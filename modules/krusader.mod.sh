MOD_ID="krusader"
MOD_NAME="Krusader"
MOD_DESC="Advanced twin-panel file manager (KDE)."
MOD_GROUP="System"

mod_check() {
  command -v krusader >/dev/null 2>&1
}

mod_install() {
  ensure_pkg "krusader"
  # Optional dependencies mentioned in legacy script
  # ensure_pkg "krenamet" "kompare" 
  # We'll stick to core for now unless requested.
}

register_module
