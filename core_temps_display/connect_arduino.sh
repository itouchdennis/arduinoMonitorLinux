#!/bin/bash

device=$(ls /dev/ttyUSB*)
echo $device

stty 9600 -F $device raw -echo
tail -f $device # assign connection &
