MOD_ID="angrysearch"
MOD_NAME="AngrySearch"
MOD_DESC="Linux file search, instant results as you type."
MOD_GROUP="Desktop Apps"

mod_check() {
  # Often installed to /usr/share/angrysearch or just has a desktop entry.
  # It doesn't always have a bin in path depending on install method, but let's check standard locations.
  if [ -d "/usr/share/angrysearch" ]; then return 0; fi
  return 1
}

mod_install() {
  # 1. Dependencies
  ensure_pkg "python3-pyqt5" "xdg-utils" "wget"

  # 2. Download from GitHub
  local repo="DoTheEvo/ANGRYsearch"
  log_info "Fetching latest release for $repo..."
  
  # Uses the generic tarball from releases
  local url
  url=$(gh_latest_asset_url "$repo" "\.tar\.gz$")
  
  if [ -z "$url" ]; then
    # Fallback to archive link if no asset found (legacy script logic)
    # Actually, gh_latest_asset_url might fail if it's just source code tags.
    # We can use the tag directly if needed, but let's try the library first.
    # If fail, use the archive format:
    local tag
    tag=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    url="https://github.com/$repo/archive/refs/tags/${tag}.tar.gz"
  fi

  local tmp_dir="/tmp/angrysearch_install"
  mkdir -p "$tmp_dir"
  local dest="$tmp_dir/angrysearch.tar.gz"
  
  log_cmd "Downloading AngrySearch" curl -L -o "$dest" "$url"
  
  # 3. Extract and Install
  log_info "Extracting..."
  tar -xzf "$dest" -C "$tmp_dir"
  
  # Find the directory (it usually has the version number)
  local extracted_dir
  extracted_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name "ANGRYsearch-*" | head -n 1)
  
  if [ -n "$extracted_dir" ]; then
    cd "$extracted_dir"
    log_info "Running install script..."
    log_cmd "Installing AngrySearch" sudo ./install.sh
  else
    log_err "Failed to find extracted directory."
    return 1
  fi
  
  rm -rf "$tmp_dir"
}

register_module
