#!/bin/bash
# Network monitoring module

#!/bin/bash

source ../../config.conf 2>/dev/null

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# -----------------------------
# Local IP Address
# -----------------------------
IP_ADDR=$(hostname -I | awk '{print $1}')

if [[ -n "$IP_ADDR" ]]; then
    echo "LOCAL_IP|$IP_ADDR|OK|$TIMESTAMP"
else
    echo "LOCAL_IP|UNKNOWN|CRITICAL|$TIMESTAMP"
fi


# -----------------------------
# Network Traffic (RX/TX bytes)
# -----------------------------
read RX TX <<< $(cat /proc/net/dev | awk '
/eth0|enp|ens|wlan/ {
    rx+=$2; tx+=$10
}
END {print rx, tx}')

if [[ -z "$RX" || -z "$TX" ]]; then
    echo "NETWORK_TRAFFIC|0|CRITICAL|$TIMESTAMP"
else
    TOTAL_TRAFFIC=$((RX + TX))

    STATUS="OK"
    if (( TOTAL_TRAFFIC > 1000000000 )); then
        STATUS="WARNING"
    fi
    if (( TOTAL_TRAFFIC > 5000000000 )); then
        STATUS="CRITICAL"
    fi

    echo "NETWORK_TRAFFIC|RX:${RX}_TX:${TX}|$STATUS|$TIMESTAMP"
fi


# -----------------------------
# Open Ports
# -----------------------------
OPEN_PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | awk -F':' '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/,$//')
if [[ -z "$OPEN_PORTS" ]]; then
    echo "OPEN_PORTS|NONE|OK|$TIMESTAMP"
else
    COUNT=$(echo "$OPEN_PORTS" | tr ',' '\n' | grep -c '[0-9]')

    STATUS="OK"
    if (( COUNT > 50 )); then
        STATUS="WARNING"
    fi
    if (( COUNT > 100 )); then
        STATUS="CRITICAL"
    fi

    echo "OPEN_PORTS|$OPEN_PORTS|$STATUS|$TIMESTAMP"
fi


# -----------------------------
# Active Connections
# -----------------------------
CONN_COUNT=$(ss -tun | wc -l)

STATUS="OK"
if (( CONN_COUNT > 200 )); then
    STATUS="WARNING"
fi
if (( CONN_COUNT > 500 )); then
    STATUS="CRITICAL"
fi

echo "ACTIVE_CONNECTIONS|$CONN_COUNT|$STATUS|$TIMESTAMP"
