#!/usr/bin/env bash

# Colors
C_RESET='\033[0m'
C_RED='\033[31m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_BLUE='\033[34m'
C_CYAN='\033[36m'
C_GRAY='\033[90m'

# Helpers
print_green()  { printf "${C_GREEN}%s${C_RESET}\n" "$@"; }
print_yellow() { printf "${C_YELLOW}%s${C_RESET}\n" "$@"; }
print_cyan()   { printf "${C_CYAN}%s${C_RESET}\n" "$@"; }
print_red()    { printf "${C_RED}%s${C_RESET}\n" "$@"; }

# Columnar Display Function (Adapted from legacy script)
display_items() {
    local cols="$1"
    shift
    local items=("$@")
    local formatted_items=()
    
    for item in "${items[@]}"; do
        formatted_items+=("$item")
    done

    # Calculate rows needed
    local count=${#formatted_items[@]}
    local rows=$(( (count + cols - 1) / cols ))
    
    for ((r=0; r<rows; r++)); do
        for ((c=0; c<cols; c++)); do
            local idx=$(( c * rows + r )) # Column-major order usually looks better for sorted lists
             # Or row-major: idx=$(( r * cols + c ))
             # Legacy script used `paste` which effectively does column-major if you split list.
             # but here simplest is row-major filling:
             idx=$(( r * cols + c ))

             if [ $idx -lt $count ]; then
                 # Use printf to pad
                 printf "%-40b" "${formatted_items[$idx]}"
             fi
        done
        printf "\n"
    done
}

# Module Menu State
declare -A MOD_INDEX_MAP
declare -a MOD_DISPLAY_LIST

# Draw Main Menu
draw_main_menu() {
    clear
    print_green "==================================="
    print_green "   SparkyLinux Modular Setup"
    print_green "   Github: https://github.com/cogitate3/setupSparkyLinux"
    print_green "==================================="
    print_yellow " Usage: Enter number to Install/Update. Add 100 to Uninstall (e.g. 1 -> Install, 101 -> Uninstall)"
    echo ""

    # Group Order preference
    local groups=("Desktop Apps" "Browsers" "Multimedia" "Dev Tools" "CLI Tools" "System" "Appearance" "Input Method" "Network & Storage" "Misc")
    
    # Track assigned indices
    local current_idx=1
    MOD_INDEX_MAP=()
    MOD_DISPLAY_LIST=()

    # Pre-calculate status for all modules (can be slow, maybe show simple list first?)
    # For now, let's just show text. Status checking can be added if fast enough.
    
    for g in "${groups[@]}"; do
        # Get modules in this group
        local invalid_ids=()
        local mod_ids=()
        for id in "${MODULE_IDS[@]}"; do
             if [[ "${M_GROUP[$id]}" == "$g" ]]; then
                 mod_ids+=("$id")
             fi
        done
        
        # If no modules in group, continue
        if [ ${#mod_ids[@]} -eq 0 ]; then continue; fi

        print_cyan ":: $g"
        local display_items_arr=()
        
        for id in "${mod_ids[@]}"; do
             local name="${M_NAME[$id]}"
             local idx_str=$(printf "%02d" $current_idx)
             
             # Check status (Cache this?)
             local status_mark="${C_GRAY}[?]${C_RESET}"
             if declare -F mod_check >/dev/null; then
                 # We need to source the module file to be sure (it should be sourced by main)
                 # In setup.sh we source all modules at start, so mod_check should exist if defined?
                 # Actually setup.sh sources them in run_module. We need to source them all for check.
                 # Optimization: Only rely on mod_check if sourced.
                 # Let's assume discover_modules sourced them or we interpret `setup.sh` doing so.
                 # setup.sh `discover_modules` does `. "$f"`. So yes, functions are available.
                 
                 # But wait, `mod_check` function name is overwritten by each module!
                 # Ah, `setup.sh` structure has a flaw!
                 # modules define `mod_check`. If we source all, the last one wins!!
                 # KEY ARCHITECTURAL ISSUE DISCOVERED.
                 :
             fi

             # Since we cannot easily check status without isolation (due to function name collision),
             # we will just display the name for now.
             # *Correction*: setup.sh currently `source`s ALL modules in `discover_modules` loop:
             # `for f in ...; do . "$f"; done`
             # This means `mod_install` etc are indeed overwritten!
             # setup.sh likely only works because it sources the module AGAIN inside `run_module`.
             # `run_module` does `. "${M_FILE[$id]}"`.
             # So the global functions are always from the 'last sourced' module.
             
             MOD_INDEX_MAP[$current_idx]="$id"
             display_items_arr+=("${C_GREEN}${idx_str}.${C_RESET} ${name}")
             ((current_idx++))
        done
        
        display_items 2 "${display_items_arr[@]}"
        echo ""
    done

    print_yellow " 0. Exit"
    print_yellow " A. Install All  |  U. Uninstall All"
    echo ""
}


# Summary Display
print_summary_table() {
    local -n results_name=$1
    local -n results_action=$2
    local -n results_status=$3
    
    echo ""
    print_green "=== Execution Summary ==="
    printf "%-30s | %-12s | %s\n" "Module" "Action" "Result"
    printf "%s\n" "-------------------------------+--------------+----------"
    
    for i in "${!results_name[@]}"; do # This loop order might be random for assoc array
        # We need to preserve order. We should pas in an index list or just use integer keys.
        # Assuming integer keys 0..N
        :
    done
    # Actually, pass arrays by value or reference?
    # Better: The caller passes parallel arrays or we just accept strict integer-indexed arrays.
}

# Redefine for simpler usage with arrays passed by reference (Bash 4.3+) is tricky if not careful.
# Let's iterate over keys provided by a separate count or just use integer indices.
draw_summary() {
    local count=$1
    # Arrays are global/env or passed by name ref
    # Let's use global arrays RES_NAME, RES_ACTION, RES_STATUS
    
    echo ""
    print_cyan "=================================================="
    print_cyan "               Processing Summary                 "
    print_cyan "=================================================="
    printf "${C_GRAY}%-4s ${C_RESET}| %-25s | %-10s | %s\n" "No." "Module" "Action" "Result"
    print_gray "-----+---------------------------+------------+-------"
    
    local success_count=0
    local fail_count=0
    
    for ((i=0; i<count; i++)); do
        local name="${RES_NAME[$i]}"
        local action="${RES_ACTION[$i]}"
        local status="${RES_STATUS[$i]}"
        local res_str=""
        
        if [ "$status" -eq 0 ]; then
            res_str="${C_GREEN}Success${C_RESET}"
            ((success_count++))
        else
            res_str="${C_RED}Failed ($status)${C_RESET}"
            ((fail_count++))
        fi
        
        printf "%-4d | %-25s | %-10s | %b\n" $((i+1)) "$name" "$action" "$res_str"
    done
    
    print_gray "--------------------------------------------------"
    if [ $fail_count -eq 0 ]; then
        print_green "All $count tasks completed successfully."
    else
        print_red "$fail_count tasks failed."
    fi
    echo ""
}

print_gray()   { printf "${C_GRAY}%s${C_RESET}\n" "$@"; }

