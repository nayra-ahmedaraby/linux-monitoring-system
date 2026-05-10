#!/bin/bash

timestamp=$(date "+%Y-%m-%d %H:%M:%S")

ports=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d: -f2 | sort -u | tr '\n' ',' | sed 's/,$//')

status="OK"

echo "OPEN_PORTS|$ports|$status|$timestamp"

