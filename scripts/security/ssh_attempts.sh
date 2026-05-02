#!/bin/bash

failed_ssh=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)

echo "FAILED_SSH=$failed_ssh"
# Security module for monitoring SSH authentication attempts
