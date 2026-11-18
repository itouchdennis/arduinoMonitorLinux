#!/bin/bash

BAUD=9600

find_device() {
  # Suche zuerst nach ttyUSB*, dann ttyACM*
  for dev in /dev/ttyUSB* /dev/ttyACM*; do
    [ -e "$dev" ] && echo "$dev" && return
  done
  return 1
}

while true; do
  DEVICE=$(find_device)

  if [ -z "$DEVICE" ]; then
    echo "[$(date)] Arduino nicht gefunden. Warte..."
    sleep 2
    continue
  fi

  echo "[$(date)] Verbunden mit $DEVICE"
  stty "$BAUD" -F "$DEVICE" raw -echo -hupcl
  tail -f "$DEVICE"

  echo "[$(date)] Verbindung getrennt. Neuer Versuch..."
  sleep 1
done
