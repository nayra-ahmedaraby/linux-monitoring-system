#!/bin/bash
# CPU monitoring module

get_cpu_usage() {
    top -bn1 | awk '/Cpu\(s\)/ {print int(100 - $8)}'
}

get_cpu_temperature() {
    sensors 2>/dev/null | awk '/Package id 0:/ {print $4}' | head -1
}

get_top_cpu_process() {
    ps -eo comm,%cpu --sort=-%cpu | awk 'NR==2 {print $1 " (" $2 "%)"}'
}
