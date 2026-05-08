#!/bin/bash
# Memory monitoring module

get_memory_usage() {
    free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}'
}

get_swap_usage() {
    free | awk '/Swap:/ {
        if ($2 == 0)
            print 0
        else
            printf("%.0f", $3/$2 * 100)
    }'
}

get_available_memory_mb() {
    free -m | awk '/Mem:/ {print $7 " MB"}'
}
