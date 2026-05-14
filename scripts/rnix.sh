#!/usr/bin/env bash

pushd ~/nixos/ > /dev/null || exit

echo -e "\033[1;34m[STAGE 1/4]\033[0m Cleaning up old logs..."
mkdir -p logs
find logs/ -name "*.log" -type f -mtime +30 -delete

TEMP_LOG="logs/rebuild_progress.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "\033[1;34m[STAGE 2/4]\033[0m Running Git add..."
git add .

echo -e "\033[1;34m[STAGE 3/4]\033[0m Starting NixOS Rebuild (Inhibiting Sleep)..."
systemd-inhibit --who="NixOS Rebuild" --why="Updating System" --mode=block \
  sudo nixos-rebuild switch --flake .#rowan-nixos 2>&1 | tee "$TEMP_LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    FINAL_LOG="logs/rebuild_${TIMESTAMP}_SUCCESS.log"
    mv "$TEMP_LOG" "$FINAL_LOG"
    
    echo -e "\033[1;32m[STAGE 4/4]\033[0m Rebuild Success. Committing to Git..."
    git add .
    git commit -m "nixos-rebuild: $TIMESTAMP"
    
    notify-send "NixOS" "Rebuild Success" -i distro-logo-nixos
else
    FINAL_LOG="logs/rebuild_${TIMESTAMP}_FAILED.log"
    mv "$TEMP_LOG" "$FINAL_LOG"
    
    echo -e "\033[1;31m[ERROR]\033[0m Rebuild failed. Check $FINAL_LOG"
    notify-send "NixOS" "Rebuild FAILED" -u critical
fi

popd > /dev/null
