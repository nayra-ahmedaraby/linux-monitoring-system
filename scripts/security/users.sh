#!/bin/bash
users=$(who | wc -l)
echo "LOGGED_USERS=$users"
# Security module for monitoring system users and accounts
