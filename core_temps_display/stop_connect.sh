#!/bin/bash
# Stop the reconnect loop first, otherwise it would immediately start a new tail
pkill -f 'connect_arduino\.sh'
# Only kill the tail that holds the Arduino serial port open, not every tail
pkill -f '^tail -f /dev/(ttyUSB|ttyACM)[0-9]+$'
exit 0
