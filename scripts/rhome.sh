#!/usr/bin/env bash

pushd ~/nixos/ > /dev/null || exit

echo -e "\033[1;34m[STAGE 1/4]\033[0m Cleaning up old logs..."
mkdir -p logs
find logs/ -name "*.log" -type f -mtime +30 -delete

TEMP_LOG="logs/home_progress.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "\033[1;34m[STAGE 2/4]\033[0m Starting Home Manager Switch..."
systemd-inhibit --who="Home Manager" --why="Updating Config" --mode=block \
  home-manager switch --flake .#ss-rowan@rowan-nixos 2>&1 | tee "$TEMP_LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    FINAL_LOG="logs/home_${TIMESTAMP}_SUCCESS.log"
    mv "$TEMP_LOG" "$FINAL_LOG"
    
    echo -e "\033[1;32m[STAGE 3/4]\033[0m Switch Success. Committing to Git..."
    git add .
    git commit -m "home-manager: $TIMESTAMP"
    git push origin main
    
    notify-send "Home Manager" "Switch Success" -i user-home
else
    FINAL_LOG="logs/home_${TIMESTAMP}_FAILED.log"
    mv "$TEMP_LOG" "$FINAL_LOG"
    
    echo -e "\033[1;31m[ERROR]\033[0m Switch failed. Check $FINAL_LOG"
    notify-send "Home Manager" "Switch FAILED" -u critical
fi

popd > /dev/null
