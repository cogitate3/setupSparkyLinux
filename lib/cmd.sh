#!/usr/bin/env bash
# lib/cmd.sh - command/dep management with distro abstraction
detect_installer(){
  for c in apt dnf pacman zypper; do command -v "$c" >/dev/null 2>&1 && { echo "$c"; return; }; done
  echo "unknown"
}

has_cmd(){ command -v "$1" >/dev/null 2>&1; }

ensure_pkg(){  # $@=pkgs
  local ins; ins="$(detect_installer)"
  local pkgs=("$@")
  
  if [ ${#pkgs[@]} -eq 0 ]; then
    return 0
  fi
  
  # 1. Check which packages actually need installation
  local targets=()
  if [ "${FORCE_REINSTALL:-0}" = "1" ]; then
      targets=("${pkgs[@]}")
  else
      for p in "${pkgs[@]}"; do
          if ! check_pkg_installed "$p"; then
              targets+=("$p")
          fi
      done
  fi
  
  if [ ${#targets[@]} -eq 0 ]; then
      log_info "所有依赖包已安装：${pkgs[*]}"
      return 0
  fi

  # 2. Perform Installation
  case "$ins" in
    apt)
            # Update Once Logic (using file marker for subshell persistence)
            local update_marker="/tmp/.sparkylinux_apt_updated"
            if [ ! -f "$update_marker" ] || [ "${FORCE_REINSTALL:-0}" = "1" ]; then
                log_cmd "apt 更新索引" sudo apt-get update -y < /dev/null
                touch "$update_marker"
            fi
            
            local opts=""
            if [ "${FORCE_REINSTALL:-0}" = "1" ]; then opts="--reinstall"; fi
            
            log_stream "apt 安装 ${targets[*]}" sudo apt-get install -y --install-recommends $opts "${targets[@]}" < /dev/null ;;
            
    dnf)    log_stream "dnf 安装 ${targets[*]}" sudo dnf install -y "${targets[@]}" < /dev/null ;;
    pacman) log_stream "pacman 同步安装 ${targets[*]}" sudo pacman -Sy --noconfirm "${targets[@]}" < /dev/null ;;
    zypper) log_stream "zypper 安装 ${targets[*]}" sudo zypper --non-interactive in "${targets[@]}" < /dev/null ;;
    *)      log_err "无法识别包管理器，安装失败：${pkgs[*]}"; return 2 ;;
  esac
}

ensure_cmd(){  # $1=cmd  $2=provider_pkg(optional)
  local cmd="$1" pkg="${2:-$1}"
  if has_cmd "$cmd"; then
    log_info "已存在命令：$cmd"
    return 0
  fi
  log_warn "缺少命令：$cmd，尝试安装包：$pkg"
  ensure_pkg "$pkg"
  if ! has_cmd "$cmd"; then
    log_err "安装后仍找不到命令：$cmd"
    return 127
  fi
}

check_pkg_installed() {
  local pkg="$1"
  if command -v dpkg >/dev/null 2>&1; then
    dpkg -s "$pkg" >/dev/null 2>&1
  elif command -v rpm >/dev/null 2>&1; then
    rpm -q "$pkg" >/dev/null 2>&1
  elif command -v pacman >/dev/null; then
    pacman -Q "$pkg" >/dev/null 2>&1
  else
    return 1
  fi
}

get_pkg_version() {
  local pkg="$1"
  if command -v dpkg >/dev/null 2>&1; then
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      # Strip epoch only, keep revision for exact match with apt-cache
      dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null | sed -E 's/^[0-9]+://'
    else
      echo "unknown"
    fi
  elif command -v rpm >/dev/null 2>&1; then
    if rpm -q "$pkg" >/dev/null 2>&1; then
      rpm -q --queryformat '%{VERSION}' "$pkg" 2>/dev/null
    else
      echo "unknown"
    fi
  else
    echo "unknown"
  fi
}

version_ge() {
    # Returns 0 if $1 >= $2
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n 1)" = "$2" ]
}

download_file() { # $1=url $2=output_path
  local url="$1" out="$2"
  log_info "Downloading: $url"
  
  if [ "${DRY_RUN:-0}" = "1" ]; then return 0; fi

  # Ensure directory exists
  mkdir -p "$(dirname "$out")"

  if command -v curl >/dev/null 2>&1; then
    # -# displays a progress ba
    if curl -L -# -o "$out" "$url"; then
      log_info "Download complete: $out"
      return 0
    else
      log_err "Download failed: $url"
      return 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    # --show-progress forces progress bar even if not a TTY (sometimes needed), or just useful
    # -q turns off other output, --show-progress brings back the ba
    if wget --show-progress -q -O "$out" "$url"; then
      log_info "Download complete: $out"
      return 0
    else
      log_err "Download failed: $url"
      return 1
    fi
  else
      log_err "No downloader (curl/wget) found!"
      return 127
  fi
}

git_clone() { # $1=url $2=target_dir $3=extra_args
  local url="$1" target="$2" args="${3:-}"
  log_info "Cloning: $url -> $target ${args:+($args)}"

  if [ "${DRY_RUN:-0}" = "1" ]; then return 0; fi

  if [ -d "$target" ]; then
      log_warn "Target directory exists, removing: $target"
      rm -rf "$target"
  fi

  # git clone outputs progress to stderr by default. 
  # We want to see it, so we DON'T capture stderr to log, but we rely on set -e behavior if it fails?
  # The calling code often pipes everything. 
  # To force it to show up, we might need to redirect stderr to /dev/tty if available, 
  # but simply running it without 'log_stream' or 'log_cmd' wrapping allows it to write to stdout/stderr freely.
  # The setup.sh main loop (run_module) does NOT silence output unless 'log_cmd' is used which redirects.
  
  if git clone --progress $args "$url" "$target"; then
      log_info "Clone success."
      return 0
  else
      log_err "Clone failed."
      return 1
  fi
}

export -f detect_installer has_cmd ensure_pkg ensure_cmd check_pkg_installed get_pkg_version version_ge download_file git_clone
