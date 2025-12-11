#!/usr/bin/env bash
# lib/gh.sh - helpers for GitHub Releases downloads
gh_latest_asset_url(){  # $1=owner/repo  $2=grep_pattern (regex for asset url)
  local repo="$1" pattern="$2" api="https://api.github.com/repos/${repo}/releases/latest"
  ensure_cmd curl
  ensure_cmd jq
  local url
  url="$(curl -fsSL "$api" | jq -r --arg re "$pattern" \
        '.assets[]?.browser_download_url | select(test($re))' | head -n1)"
  [ -n "$url" ] || { log_err "未在 $repo 的最新发布中找到匹配：$pattern"; return 1; }
  echo "$url"
}

# Get latest tag name (version) from GitHub
gh_get_latest_tag() {
  local repo="$1"
  # Try API first
  local tag
  tag=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  
  if [ -z "$tag" ]; then
    # Fallback: Scrape releases page (simple regex, fragile but works for many)
    tag=$(curl -s "https://github.com/$repo/releases" | grep -oE 'href="/'"$repo"'/releases/tag/[^"]+"' | head -n 1 | sed -E 's/.*tag\/([^"]+)"/\1/')
  fi
  
  echo "$tag"
}

gh_pick_asset(){  # $1=owner/repo  prefers: .deb > .AppImage > .tar.gz
  local repo="$1" url
  for re in 'deb$' 'AppImage$' 'tar\.gz$'; do
    url="$(gh_latest_asset_url "$repo" "$re")" && { echo "$url"; return 0; }
  done
  log_err "在 $repo 中未能按优先级找到合适资产"
  return 1
}
