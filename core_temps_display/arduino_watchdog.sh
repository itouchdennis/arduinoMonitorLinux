#!/bin/bash

DEVICE="/dev/arduino"
SERVICE="arduino-connect.service"
TIMEOUT=5  # seconds to consider no response

while true; do
    if [ ! -e "$DEVICE" ]; then
        echo "[$(date)] Device $DEVICE not found. Restarting $SERVICE..."
        systemctl restart $SERVICE
        sleep 10
        continue
    fi

    # Try reading a byte with timeout
    stty -F "$DEVICE" 9600 raw -echo

    if timeout 3 dd if="$DEVICE" bs=1 count=1 2>/dev/null | grep -q '.'; then
        # Got data
        echo "[$(date)] Device responsive."
    else
        echo "[$(date)] No data from device. Restarting $SERVICE..."
        systemctl restart $SERVICE
    fi

    sleep 10
done
