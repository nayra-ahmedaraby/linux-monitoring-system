#!/bin/bash
ports=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2 | sort -u | tr '\n' ',' | sed 's/,$//')
echo "OPEN_PORTS=$ports"
# Security module for monitoring open network ports
