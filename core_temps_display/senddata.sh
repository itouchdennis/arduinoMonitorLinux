#!/bin/bash

#get device
sleep 6
device=$(ls /dev/ttyUSB*)
deviceNames="0: Intel Core, i5 12600k, Nvidia, RTX 3070 TI,;"
standalone=false
echo $device

while true
do
#asign vars
cpuTemp=$(sensors | grep "CPU:" | cut -d "+" -f2 | cut -c -4 | cut -d "." -f1)
cpuUsage=$(top -bn 1 | grep '%Cpu' | tail -1 | grep -P '(....|...) id,'|awk '{print "" 100-$8}')
ramUsage="$(free | awk '/Mem/{printf("Mem used: %.1f%"), $3/($2+.000000001)*100} /buffers\/cache/{printf(", buffers: %.1f%"), $4/($3+$4)+.000000001*100} /Swap/{printf(", swap: %.1f%"), $3/($2+.000000001)*100}' | cut -d " " -f 3 | cut -c -2 | cut -d "." -f 1)"
waterTemp=$(sensors | grep "External sensor:" | cut -d "+" -f2 | cut -c -4)
nvidiaVoltage=$(nvidia-smi -q | grep mV | cut -d ":" -f 2 | cut -c -4 | cut -c 2-)
nvidiaUsage=$(nvidia-smi -q  | grep "Gpu" | cut -d ":" -f 2 | cut -c 2- | cut -c -2)
gpuTemp=$(nvidia-smi -q | grep "GPU Current Temp" | cut -d ":" -f 2 | cut -c -3 | cut -c 2-)
moboTemp=$(sensors | grep "System:" | cut -d "+" -f2 | cut -c -4 | cut -d "." -f1)
moboTemp=" $moboTemp"
cpuTemp=" $cpuTemp"
gpuTemp=" ${gpuTemp}"
nvidiaVoltage="${nvidiaVoltage}"
date=$(date "+%H:%M")
date="$date"
#Formatting output
if [ ${#nvidiaUsage} == 1 ]; then
    nvidiaUsage=" 0$nvidiaUsage"
fi
if [ ${#nvidiaUsage} == 2 ]; then
    nvidiaUsage=" $nvidiaUsage"
fi

#Formatting output
if [ ${#ramUsage} == 1 ]; then
    ramUsage=" 0$ramUsage"
fi
if [ ${#ramUsage} == 2 ]; then
    ramUsage=" $ramUsage"
fi

if [ ${#cpuUsage} == 1 ]; then
    cpuUsage=" 0${cpuUsage}"
fi
if [ ${#cpuUsage} == 2 ]; then
    cpuUsage=" ${cpuUsage}"
fi

#echo $device
if [[ -z "$device" && $standalone == true ]];then
    echo "No device can be found"
    ./stop_connect.sh
else
    #build connection
    connected=$(ps aux | grep "[c]onnect_arduino")
    if [[ -z "$connected" ]];then
        echo "Building connection"
        ./connect_arduino.sh &
    fi
fi

    #test connection
    #connect="*****;" #TestConnectionString#
    #echo $connect > $device
    #cat $device | tee output.txt

    #
    #assign vars
    devices=$deviceNames
    temps1="1:$cpuTemp,$cpuUsage,$ramUsage,$date,;"
    temps2="2:$gpuTemp,$nvidiaUsage,$nvidiaVoltage,$waterTemp,;"

    echo $devices > $device
    echo $temps1 > $device
    echo $temps2 > $device
    echo "3:;" > $device

sleep 1
done
    # echo "2:10,10,13,13,;" > $device

