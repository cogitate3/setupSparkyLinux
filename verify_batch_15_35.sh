#!/usr/bin/env bash
source lib/log.sh
source lib/cmd.sh
source lib/gh.sh

check_mod() {
  local id="$1"
  local f="modules/$id.mod.sh"
  if [ -f "$f" ]; then
    source "$f"
    echo ">>> Module: $MOD_NAME ($id)"
    mod_status
    echo "    RC: $?"
    echo "--------------------------------"
  else
    echo "!!! Missing module file for $id"
  fi
}

# 15-35 based on inspecting menu order
ids=(
"cheat" "eg" "micro" "neofetch"
"autostart" "docker" "flatpak" "homebrew" "konsole" "krusader" "snap" "spacefm" "sudo-esc" "telegram"
"fonts" "plank"
"rime"
"davfs2" "rclone" "sshfs"
)

for id in "${ids[@]}"; do
    (check_mod "$id")
done
