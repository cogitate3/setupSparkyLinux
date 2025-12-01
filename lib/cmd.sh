#!/usr/bin/env bash
# lib/cmd.sh - command/dep management with distro abstraction
detect_installer(){
  for c in apt dnf pacman zypper; do command -v "$c" >/dev/null 2>&1 && { echo "$c"; return; }; done
  echo "unknown"
}

has_cmd(){ command -v "$1" >/dev/null 2>&1; }

ensure_pkg(){  # $1=pkg
  local pkg="$1" ins; ins="$(detect_installer)"
  case "$ins" in
    apt)    log_cmd "apt 更新索引" sudo apt-get update -y
            log_cmd "apt 安装 $pkg" sudo apt-get install -y "$pkg" ;;
    dnf)    log_cmd "dnf 安装 $pkg" sudo dnf install -y "$pkg" ;;
    pacman) log_cmd "pacman 同步安装 $pkg" sudo pacman -Sy --noconfirm "$pkg" ;;
    zypper) log_cmd "zypper 安装 $pkg" sudo zypper --non-interactive in "$pkg" ;;
    *)      log_err "无法识别包管理器，安装失败：$pkg"; return 2 ;;
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
