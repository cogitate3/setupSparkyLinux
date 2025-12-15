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
  
  case "$ins" in
    apt)    log_cmd "apt 更新索引" sudo apt-get update -y
            log_cmd "apt 安装 ${pkgs[*]}" sudo apt-get install -y --install-recommends "${pkgs[@]}" ;;
    dnf)    log_cmd "dnf 安装 ${pkgs[*]}" sudo dnf install -y "${pkgs[@]}" ;;
    pacman) log_cmd "pacman 同步安装 ${pkgs[*]}" sudo pacman -Sy --noconfirm "${pkgs[@]}" ;;
    zypper) log_cmd "zypper 安装 ${pkgs[*]}" sudo zypper --non-interactive in "${pkgs[@]}" ;;
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
