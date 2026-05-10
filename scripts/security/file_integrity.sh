#!/bin/bash

BASELINE_FILE="../../baseline/passwd.hash"

current_hash=$(md5sum /etc/passwd | awk '{print $1}')

if [ ! -f "$BASELINE_FILE" ]; then
    echo "$current_hash" > "$BASELINE_FILE"
    echo "STATUS=BASELINE_CREATED"
else
    old_hash=$(cat "$BASELINE_FILE")

    if [ "$current_hash" = "$old_hash" ]; then
        echo "STATUS=OK"
    else
        echo "STATUS=CHANGED"
        echo "OLD_HASH=$old_hash"
        echo "NEW_HASH=$current_hash"

        echo "$current_hash" > "$BASELINE_FILE"
    fi
fi
