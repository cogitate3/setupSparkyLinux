#!/usr/bin/env bash

for f in modules/*.mod.sh; do
    echo "=== $(basename "$f") ==="
    # Extract lines between mod_uninstall() { and the matching closing brace
    # This is a bit tricky with sed/grep, so let's just grep the function body crudely
    # Assuming standard formatting: mod_uninstall() { ... }
    
    if ! grep -q "mod_uninstall" "$f"; then
        echo "[WARN] No mod_uninstall function found!"
        continue
    fi
    
    # Simple extraction: find start line, print until '}' at start of line or similar indentation
    # Actually, let's just print the function definition using sed
    sed -n '/^mod_uninstall()/,/^}/p' "$f"
    echo ""
done
