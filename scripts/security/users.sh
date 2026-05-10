#!/bin/bash

timestamp=$(date "+%Y-%m-%d %H:%M:%S")

users=$(who | wc -l)

status="OK"

echo "LOGGED_USERS|$users|$status|$timestamp"
