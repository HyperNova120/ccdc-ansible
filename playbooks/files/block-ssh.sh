#!/bin/bash

WAITTIME="10"

LOG_FILE="/var/log/Block_SSH"
BLOCKED_LOG_FILE="/var/log/Block_SSH-blocked"
echo "Invoked at $(date)" >> "$LOG_FILE"

# Read JSON payload from Wazuh
PAYLOAD=$(timeout 1 cat)
echo "payload:$PAYLOAD" >> "$LOG_FILE"

SRCIP=$(echo "$PAYLOAD" | jq -r '.parameters.alert.data.srcip')
echo "Source IP: $SRCIP" >> "$LOG_FILE"

sleep "$WAITTIME"

# Find all sshd or sshd-session PIDs associated with this IP
PIDS=$(ss -tnp | awk -v ip="$SRCIP" '
    /ESTAB/ && $0 ~ ip {
        while (match($0, /pid=([0-9]+)/, m)) {
            print m[1]
            $0 = substr($0, RSTART + RLENGTH)
        }
    }
')

if [ -z "$PIDS" ]; then
    echo "No SSH sessions found for $SRCIP" >> "$LOG_FILE"
else
    for pid in $PIDS; do
        if [[ "$pid" =~ ^[0-9]+$ ]]; then
            echo "Killing SSH PID $pid for $SRCIP" >> "$LOG_FILE"
            kill "$pid"
            echo "$(date '+%Y/%m/%d %H:%M:%S') | $SRCIP" >> "$BLOCKED_LOG_FILE"
        else
            echo "Invalid PID detected: $pid" >> "$LOG_FILE"
        fi
    done
fi

# Required Wazuh AR response
echo '{"version":1,"origin":{"name":"block-ssh","module":"active-response"},"command":"delete"}'
exit 0
