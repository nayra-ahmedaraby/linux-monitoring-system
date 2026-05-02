#!/bin/bash
zombies=$(ps aux | awk '{ if ($8=="Z") print }' | wc -l)
echo "ZOMBIES=$zombies"
# Security module for monitoring and managing zombie processes
