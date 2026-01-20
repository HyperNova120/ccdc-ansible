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

# Loop through all pts sessions
while IFS= read -r pts; do
    echo "Checking $pts" >> "$LOG_FILE"

    pid=$(ps aux | grep "$pts" | grep @ | grep -v grep | awk '{print $2}')

    if [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "Killing SSH PID $pid for $SRCIP" >> "$LOG_FILE"
        kill "$pid"
        echo "$(date '+%Y/%m/%d %H:%M:%S') | $SRCIP" >> "$BLOCKED_LOG_FILE"
    else
        echo "No valid PID found for $pts" >> "$LOG_FILE"
    fi

done < <(who | grep -oE 'pts/[0-9]+')

# Required Wazuh AR response
echo '{"version":1,"origin":{"name":"block-ssh","module":"active-response"},"command":"delete"}'
exit 0
