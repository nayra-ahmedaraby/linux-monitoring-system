#!/bin/bash
# Network monitoring module

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

connections=$(ss -tun | tail -n +2 | wc -l)

echo "ACTIVE_CONNECTIONS|${connections}|OK|${TIMESTAMP}"