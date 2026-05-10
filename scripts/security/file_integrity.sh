#!/bin/bash

BASELINE_FILE="baseline/passwd.hash"

current_hash=$(md5sum /etc/passwd | awk '{print $1}')
timestamp=$(date "+%Y-%m-%d %H:%M:%S")

if [ ! -f "$BASELINE_FILE" ]; then
    echo "$current_hash" > "$BASELINE_FILE"

    echo "PASSWD_HASH|BASELINE_CREATED|OK|$timestamp"

else
    old_hash=$(cat "$BASELINE_FILE")

    if [ "$current_hash" = "$old_hash" ]; then

        echo "PASSWD_HASH|UNCHANGED|OK|$timestamp"

    else

        echo "PASSWD_HASH|CHANGED|CRITICAL|$timestamp"

        echo "$current_hash" > "$BASELINE_FILE"

    fi
fi
