#!/bin/bash

BASELINE_FILE="baseline/passwd.hash"

current_hash=$(md5sum /etc/passwd | awk '{print $1}')

timestamp=$(date "+%Y-%m-%d %H:%M:%S")
echo "TIMESTAMP=$timestamp"

if [ ! -f "$BASELINE_FILE" ]; then
    echo "$current_hash" > "$BASELINE_FILE"
    echo "PASSWD_STATUS=BASELINE_CREATED"
else
    old_hash=$(cat "$BASELINE_FILE")

    if [ "$current_hash" = "$old_hash" ]; then
        echo "PASSWD_STATUS=OK"
    else
        echo "PASSWD_STATUS=CHANGED"
        echo "OLD_HASH=$old_hash"
        echo "NEW_HASH=$current_hash"

        echo "$current_hash" > "$BASELINE_FILE"
    fi
fi
