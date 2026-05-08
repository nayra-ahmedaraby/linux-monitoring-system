#!/bin/bash
# System load monitoring module

get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs
}

get_uptime() {
    uptime -p
}

get_logged_users() {
    who | wc -l
}
