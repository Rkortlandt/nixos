#!/bin/bash

# 1. Configuration - MAKE SURE THIS MATCHES YOUR FILE MANAGER
FILE_MANAGER="nemo" 

# 2. Find the socket dynamically
# We use 'printf' to ensure the path doesn't have trailing newlines/spaces
HYPR_SOCKET=$(find "$XDG_RUNTIME_DIR/hypr" -maxdepth 2 -name ".socket2.sock" -print -quit)

if [ -z "$HYPR_SOCKET" ]; then
    echo "Hyprland socket not found."
    exit 1
fi

# 3. The Listener Logic
# Note: We use -u (unbuffered) for socat and ensure the address is clean
socat -u UNIX-CONNECT:"$HYPR_SOCKET" - | while read -r line; do
    echo "Event: $line"
    if [[ $line == "openwindow>>"* ]]; then
       clean_line=$(echo "$line" | sed 's/openwindow>>//')
        
        # Extract fields based on your log: address, workspace, class, title
        ADDR=$(echo "$clean_line" | cut -d',' -f1)
        WS_NAME=$(echo "$clean_line" | cut -d',' -f2)
        CLASS=$(echo "$clean_line" | cut -d',' -f3)

        if [[ "$CLASS" == "$FILE_MANAGER" ]]; then
            # Count windows in the workspace where Nemo just opened
            # We use jq to get the window count directly from the workspace object
            COUNT=$(hyprctl workspaces -j | jq ".[] | select(.name == \"$WS_NAME\") | .windows")
            
            # Default to 0 if count is null
            COUNT=${COUNT:-0}

            if [ "$COUNT" -eq 1 ]; then
                # Tiny delay to ensure the window is 'ready' for the dispatch command
                sleep 0.1
                hyprctl dispatch togglefloating address:0x$ADDR
                echo "Successfully floated Nemo at 0x$ADDR (Workspace $WS_NAME has $COUNT windows)"
            fi
        fi
    fi
done
