#!/bin/bash
# Network monitoring module

get_active_connections() {
    ss -tun | tail -n +2 | wc -l
}

get_listening_ports() {
    ss -tuln | grep LISTEN | wc -l
}

get_primary_ip() {
    hostname -I | awk '{print $1}'
}

get_network_traffic() {
    ip -s link | awk '
        /RX:/ {getline; rx += $1}
        /TX:/ {getline; tx += $1}
        END {
            printf("RX: %.2f MB | TX: %.2f MB", rx/1024/1024, tx/1024/1024)
        }'
}
