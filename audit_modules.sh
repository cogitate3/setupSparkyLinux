#!/usr/bin/env bash
# audit_modules.sh - Automated Tester Agent Script

# Use full path for report to avoid subshell issues
REPORT_FILE="$(pwd)/audit_report.log"

source lib/log.sh >/dev/null 2>&1
source lib/cmd.sh >/dev/null 2>&1
source lib/gh.sh >/dev/null 2>&1

# Mock environment
export DRY_RUN=1 

# Store results
echo "=== SetupSparkyLinux Module Audit Report ($(date)) ===" > "$REPORT_FILE"
echo "System Arch: $(uname -m)" >> "$REPORT_FILE"
echo "--------------------------------------------------" >> "$REPORT_FILE"

# Trackers
total=0
passed=0
failed=0

audit_module() {
    local mod_file="$1"
    local mod_id=$(basename "$mod_file" .mod.sh)
    
    # Run everything in a subshell to prevent pollution
    # Pass REPORT_FILE to subshell
    (
        source lib/log.sh >/dev/null 2>&1
        source lib/cmd.sh >/dev/null 2>&1
        source lib/gh.sh >/dev/null 2>&1
        
        register_module() { :; }
        check_pkg_installed() { dpkg -s "$1" >/dev/null 2>&1; }
        export -f register_module check_pkg_installed

        # Source the module
        source "$mod_file"

        # 1. Test mod_status
        echo -n "Audit [$mod_id]: Testing mod_status... " >> "$REPORT_FILE"
        local status_output; status_output=$(mod_status 2>/dev/null)
        local ret=$?
        if [ $ret -le 2 ]; then
            echo "PASS (Result: $status_output, Code: $ret)" >> "$REPORT_FILE"
        else
            echo "FAIL (Code: $ret, Error: $status_output)" >> "$REPORT_FILE"
            exit 1 
        fi

        # 2. Test Download Link
        echo -n "Audit [$mod_id]: Testing download link... " >> "$REPORT_FILE"
        rm -f /tmp/last_url
        
        ensure_pkg() { 
           for arg in "$@"; do 
             if [[ "$arg" == http* ]]; then echo "$arg" > /tmp/last_url; fi
           done
        }
        # Mock log_info to capture URLs from DRY-RUN messages
        log_info() {
            local msg="$*"
            if [[ "$msg" == *"DRY-RUN:"* && "$msg" == *"http"* ]]; then
                echo "$msg" | grep -oP 'http\S+' > /tmp/last_url
            fi
            # Still print it to stderr for debugging if needed
            echo "[INFO] $msg" >&2
        }
        # Still need to mock curl/wget for modules that don't use log_cmd or when DRY_RUN=0
        curl() {
            for arg in "$@"; do
                if [[ "$arg" == http* ]]; then 
                    if [[ "$arg" == *api.github.com* || "$arg" == *raw.githubusercontent.com* ]]; then
                        /usr/bin/curl "$@"
                        return $?
                    else
                        echo "$arg" > /tmp/last_url
                        return 0
                    fi
                fi
            done
            /usr/bin/curl "$@"
        }
        sudo() { return 0; }
        
        mod_install >/dev/null 2>&1

        if [ -f /tmp/last_url ]; then
            local url=$(cat /tmp/last_url)
            if [[ "$url" == "pipx "* ]]; then
                 echo "PASS (pipx: $url)" >> "$REPORT_FILE"
            elif /usr/bin/curl --output /dev/null --silent --head --fail "$url"; then
                echo "PASS ($url)" >> "$REPORT_FILE"
            else
                echo "FAIL (Link Broken: $url)" >> "$REPORT_FILE"
                exit 1
            fi
        else
            echo "SKIP (No URL detected)" >> "$REPORT_FILE"
        fi
        exit 0
    )
    
    if [ $? -eq 0 ]; then
        ((passed++))
    else
        ((failed++))
    fi
}

for f in modules/*.mod.sh; do
    ((total++))
    audit_module "$f"
done

echo "--------------------------------------------------" >> "$REPORT_FILE"
echo "Total: $total | Passed/Skipped: $passed | Failed: $failed" >> "$REPORT_FILE"
cat "$REPORT_FILE"
