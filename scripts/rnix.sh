#!/usr/bin/env bash

# Save current directory and move to config
pushd ~/nixos/ > /dev/null || exit

# 1. Setup & Cleanup
echo -e "\033[1;34m[STAGE 1/4]\033[0m Cleaning up old logs..."
mkdir -p logs
find logs/ -name "*.log" -type f -mtime +30 -delete

TEMP_LOG="logs/rebuild_progress.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 2. The Build
echo -e "\033[1;34m[STAGE 2/4]\033[0m Starting NixOS Rebuild (Inhibiting Sleep)..."
systemd-inhibit --who="NixOS Rebuild" --why="Updating System" --mode=block \
  sudo nixos-rebuild switch --flake .#rowan-nixos 2>&1 | tee "$TEMP_LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    FINAL_LOG="logs/rebuild_${TIMESTAMP}_SUCCESS.log"
    mv "$TEMP_LOG" "$FINAL_LOG"
    
    # 3. Git Operations
    echo -e "\033[1;32m[STAGE 3/4]\033[0m Rebuild Success. Committing to Git..."
    git add .
    git commit -m "nixos-rebuild: $TIMESTAMP"
    
    # 4. Notification
    notify-send "NixOS" "Rebuild Success" -i distro-logo-nixos
else
    FINAL_LOG="logs/rebuild_${TIMESTAMP}_FAILED.log"
    mv "$TEMP_LOG" "$FINAL_LOG"
    
    echo -e "\033[1;31m[ERROR]\033[0m Rebuild failed. Check $FINAL_LOG"
    notify-send "NixOS" "Rebuild FAILED" -u critical
fi

# Return to original directory
popd > /dev/null
