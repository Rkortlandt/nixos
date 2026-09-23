#!/usr/bin/env bash

CAVA_BIN=$(which cava 2>/dev/null)
if [ -z "$CAVA_BIN" ]; then
    CAVA_BIN=$(find /nix/store -maxdepth 3 -name cava -type f -perm -111 2>/dev/null | grep -E '/bin/cava$' | head -n 1)
fi

if [ -z "$CAVA_BIN" ] || [ ! -x "$CAVA_BIN" ]; then
    while true; do
        echo "30;60;25;"
        sleep 0.1
    done
    exit 0
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$DIR/cava.conf"

exec "$CAVA_BIN" -p "$CONF"
