#!/usr/bin/env bash
source lib/menu.sh

# Mock arrays if not loaded
declare -A M_NAME M_GROUP M_DESC
MODULE_IDS=()

# Load real modules
for f in modules/*.mod.sh; do
    source "$f"
    MODULE_IDS+=("$MOD_ID")
    M_NAME["$MOD_ID"]="${MOD_NAME}"
    M_GROUP["$MOD_ID"]="${MOD_GROUP}"
done

# Redefine clear to not clear
clear() { echo "--- CLEAR ---"; }

# Force draw_main_menu
draw_main_menu
