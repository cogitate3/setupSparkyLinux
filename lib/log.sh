#!/usr/bin/env bash
# lib/log.sh - unified logging + command runner (color, timestamp, DRY_RUN, retry)
: "${LOG_FILE:=/tmp/setupSparkyLinux.log}"
: "${DRY_RUN:=0}"
# : 是 shell 里的 “空命令”，啥也不干但返回成功（用来触发参数展开而不执行命令）
# ${LOG_FILE:=默认值} 是参数扩展语法：如果LOG_FILE变量没设置或为空，就把它设为/tmp/setupSparkyLinux.log
# 效果：如果用户没提前定义LOG_FILE变量，就自动把它初始化为日志文件路径 /tmp/setupSparkyLinux.log

_ts() { date +"%F %T"; }
# _ts() { date +"%F %T"; } 是一个函数定义，定义了一个名为 _ts 的函数，它返回当前日期和时间。
# date +"%F %T" 是一个命令，用于获取当前日期和时间，格式为：
# %F 表示年-月-日
# %T 表示时:分:秒
# 整体效果：_ts() 函数返回当前日期和时间，格式为：2025-12-10 23:46:28

_log_core() {  # $1=level $2=message
  local lvl="$1" msg="$2" r="\033[0m" c1="\033[1;36m" c2="\033[1;33m" c3="\033[1;31m"
  case "$lvl" in
    INFO) printf "${c1}[%s] [INFO] %s${r}\n" "$(_ts)" "$msg" ;;
    WARN) printf "${c2}[%s] [WARN] %s${r}\n" "$(_ts)" "$msg" ;;
    ERR)  printf "${c3}[%s] [ERR ] %s${r}\n" "$(_ts)" "$msg" ;;
    *)    printf "[%s] [%s] %s\n" "$(_ts)" "$lvl" "$msg" ;;
  esac | tee -a "$LOG_FILE"
}

log_info(){ _log_core INFO "$*"; }
log_warn(){ _log_core WARN "$*"; }
log_err() { _log_core ERR  "$*"; }

retry(){ # retry N delay_secs -- cmd...
  local n="$1"; shift
  local d="$1"; shift
  local i rc
  for ((i=1;i<=n;i++)); do
    "$@"
    rc=$?
    [ $rc -eq 0 ] && return 0
    [ $i -lt $n ] && { log_warn "第${i}次失败(rc=$rc)，${d}s后重试：$*"; sleep "$d"; }
  done
  return $rc
}

log_cmd(){  # log_cmd "描述" cmd args...
  local desc="$1"; shift
  if [ "$DRY_RUN" = "1" ]; then
    log_info "DRY-RUN: ${desc} ⇒ $*"
    return 0
  fi
  log_info "RUN: ${desc} ⇒ $*"
  if "$@" >>"$LOG_FILE" 2>&1; then
    log_info "OK : ${desc}"
  else
    local rc=$?
    log_err  "FAIL(${rc}): ${desc}（详见 $LOG_FILE）"
    return $rc
  fi
}
