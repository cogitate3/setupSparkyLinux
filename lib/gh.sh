#!/usr/bin/env bash
# lib/gh.sh - helpers for GitHub Releases downloads
gh_latest_asset_url(){  # $1=owner/repo  $2=regex  $3=arch_aware(1/0)
  local repo="$1" pattern="$2" arch_aware="${3:-1}"
  local api="https://api.github.com/repos/${repo}/releases/latest"
  ensure_cmd curl
  ensure_cmd jq
  
  local json; json="$(curl -fsSL "$api" < /dev/null)" || return 1
  # ... (omitted lines not being replaced but context match)
  # But replace_file_content needs exact scope.
  # I'll replace the full blocks if I can, or use multi_replace.
  local url=""

  if [ "$arch_aware" = "1" ]; then
      # Detect current architecture
      local arch=$(uname -m)
      local arch_re=""
      case "$arch" in
        x86_64) arch_re="(amd64|x86[-_]64|x64)" ;;
        aarch64|arm64) arch_re="(arm[-_]?64|aarch64|armv8)" ;;
        arm*) arch_re="arm" ;;
        *) arch_re="$arch" ;;
      esac

      # Try matching both pattern AND system architecture
      url=$(echo "$json" | jq -r --arg re "$pattern" --arg are "$arch_re" \
            '.assets[]? | .browser_download_url | select(test($re; "i") and test($are; "i"))' | head -n1)
  fi
  
  # Fallback: Just match the pattern (or if arch_aware=0)
  if [ -z "$url" ]; then
    url=$(echo "$json" | jq -r --arg re "$pattern" \
        '.assets[]? | .browser_download_url | select(test($re; "i"))' | head -n1)
  fi

  [ -n "$url" ] || { return 1; }
  echo "$url"
}

# Legacy compatibility wrapper
get_download_link() {
  local gh_url="$1" regex="$2"
  # Extract owner/repo from URL
  local repo=$(echo "$gh_url" | sed -E 's|https://github.com/([^/]+/[^/]+).*|\1|')
  
  DOWNLOAD_URL=$(gh_latest_asset_url "$repo" "$regex" 0)
  local ret=$?
  
  if [ $ret -eq 0 ]; then
    echo "$DOWNLOAD_URL"
  fi
  return $ret
}

# Get latest tag name (version) from GitHub
gh_get_latest_tag() {
  local repo="$1"
  # Try API first
  local tag
  tag=$(curl -s "https://api.github.com/repos/$repo/releases/latest" < /dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  
  if [ -z "$tag" ]; then
    # Fallback: Scrape releases page (simple regex, fragile but works for many)
    tag=$(curl -s "https://github.com/$repo/releases" < /dev/null | grep -oE 'href="/'"$repo"'/releases/tag/[^"]+"' | head -n 1 | sed -E 's/.*tag\/([^"]+)"/\1/')
  fi
  
  echo "$tag"
}

gh_pick_asset(){  # $1=owner/repo  $2=filter (optional, e.g. "deb")
  local repo="$1" ext_filter="${2:-}" url
  
  if [ -n "$ext_filter" ]; then
    # Escape dots for regex
    local re="${ext_filter//./\\.}"
    # Match the extension at the end of the URL
    url="$(gh_latest_asset_url "$repo" "${re}\$")" && { echo "$url"; return 0; }
    return 1
  fi

  # Default priority if no filter
  for re in '\.deb$' 'AppImage$' '\.tar\.gz$'; do
    url="$(gh_latest_asset_url "$repo" "$re")" && { echo "$url"; return 0; }
  done
  
  log_err "在 $repo 中未能按优先级找到合适资产"
  return 1
}

export -f gh_latest_asset_url get_download_link gh_get_latest_tag gh_pick_asset
