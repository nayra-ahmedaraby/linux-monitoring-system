#!/bin/bash
# Disk monitoring module

get_disk_usage() {
    df / | awk 'NR==2 {
        gsub("%","",$5)
        print $5
    }'
}

get_disk_free_space() {
    df -h / | awk 'NR==2 {print $4}'
}

get_largest_directory() {
    du -h /home 2>/dev/null | sort -rh | head -1 | awk '{print $2}'
}
