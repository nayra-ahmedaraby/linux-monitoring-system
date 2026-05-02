#!/bin/bash
ssh_status=$(systemctl is-active ssh 2>/dev/null)
cron_status=$(systemctl is-active cron 2>/dev/null)

echo "SSH_STATUS=$ssh_status"
echo "CRON_STATUS=$cron_status"
# Security module for monitoring system services status
