#!/bin/bash

FILE_MANAGER="nemo" 
HYPR_SOCKET=$(find "$XDG_RUNTIME_DIR/hypr" -maxdepth 2 -name ".socket2.sock" -print -quit)

if [ -z "$HYPR_SOCKET" ]; then
    echo "Hyprland socket not found."
    exit 1
fi

socat -u UNIX-CONNECT:"$HYPR_SOCKET" - | while read -r line; do
    echo "Event: $line"
    if [[ $line == "openwindow>>"* ]]; then
       clean_line=$(echo "$line" | sed 's/openwindow>>//')
        
        ADDR=$(echo "$clean_line" | cut -d',' -f1)
        WS_NAME=$(echo "$clean_line" | cut -d',' -f2)
        CLASS=$(echo "$clean_line" | cut -d',' -f3)

        if [[ "$CLASS" == "$FILE_MANAGER" ]]; then
            COUNT=$(hyprctl workspaces -j | jq ".[] | select(.name == \"$WS_NAME\") | .windows")
            
            COUNT=${COUNT:-0}

            if [ "$COUNT" -eq 1 ]; then
                sleep 0.1
                hyprctl dispatch togglefloating address:0x$ADDR
                echo "Successfully floated Nemo at 0x$ADDR (Workspace $WS_NAME has $COUNT windows)"
            fi
        fi
    fi
done
