#!/bin/bash

#get device
sleep 5
device=$(ls /dev/ttyUSB*)
deviceNames="0: Intel Core, i5 12600k, AMD, 9070 XT ,;"
standalone=false
echo $device

while true
do
#asign vars
#cpuTemp=$(sensors 2> /dev/null | grep "CPU:" | cut -d "+" -f2 | cut -c -4 | cut -d "." -f1)
cpuTemp=$(sensors 2> /dev/null | grep "Package id 0:" | cut -d "+" -f2 | cut -c -4 | cut -d "." -f1)
#cpuUsage=$(top -bn 1 | grep '%Cpu' | tail -1 | grep -P '(....|...) id,'|awk '{print "" 100-$8}')
cpuUsage=$(top -bn 1 | grep '%Cpu' | tail -1 | awk '{printf("%d\n", 100 - $8)}')

ramUsage="$(free | awk '/Mem/{printf("Mem used: %.1f%"), $3/($2+.000000001)*100} /buffers\/cache/{printf(", buffers: %.1f%"), $4/($3+$4)+.000000001*100} /Swap/{printf(", swap: %.1f%"), $3/($2+.000000001)*100}' | cut -d " " -f 3 | cut -c -2 | cut -d "." -f 1)"
waterTemp=$(sensors 2> /dev/null | grep "External sensor:" | cut -d "+" -f2 | cut -c -4)
#nvidiaVoltage=$(nvidia-smi -q | grep mV | cut -d ":" -f 2 | cut -c -4 | cut -c 2-)
#nvidiaUsage=$(nvidia-smi -q  | grep "Gpu" | cut -d ":" -f 2 | cut -c 2- | cut -c -2)
#nvidiaUsage=$(nvidia-smi -q | awk -F': ' '/GPU/ && /%$/ {gsub(" %", "", $2); print $2}')
# gpuTemp=$(nvidia-smi -q | grep "GPU Current Temp" | cut -d ":" -f 2 | cut -c -3 | cut -c 2-)
moboTemp=$(sensors 2> /dev/null | grep "System:" | cut -d "+" -f2 | cut -c -4 | cut -d "." -f1)
moboTemp=" $moboTemp"
cpuTemp=" $cpuTemp"
# gpuTemp=" ${gpuTemp}"
#nvidiaVoltage=$(sensors 2> /dev/null | grep "vddgfx:" | cut -d':' -f2 | cut -d'.' -f1 | tr -d ' ')
nvidiaVoltage="${nvidiaVoltage}"
gpuTemp=$(sensors 2> /dev/null | grep "junction:" | cut -d "+" -f2 | cut -c -4 | cut -d'.' -f1)
gpuTemp=" ${gpuTemp}"
date=$(date "+%H:%M")
date="$date"

json=$(amdgpu_top -J -n 1)
nvidiaVoltage="$(echo "$json" |  jq '.devices[0].Sensors.VDDGFX.value')"
vram_total=$(echo "$json" | jq '.devices[0].VRAM."Total VRAM".value')
vram_used=$(echo "$json" | jq '.devices[0].VRAM."Total VRAM Usage".value')

# Calculate percentage
nvidiaUsage=$(awk "BEGIN {printf \"%.0f\", ($vram_used / $vram_total) * 100}")


#Formatting output
# To do write function 
if [ ${#nvidiaUsage} == 1 ]; then
    nvidiaUsage=" 0$nvidiaUsage"
fi
if [ ${#nvidiaUsage} == 2 ]; then
    nvidiaUsage=" $nvidiaUsage"
fi

if [ ${#nvidiaUsage} == 3 ]; then
    nvidiaUsage=" $nvidiaUsage"
fi

if [ ${#nvidiaUsage} == 4 ]; then
    nvidiaUsage=" $nvidiaUsage"
fi

#Formatting output
# To do write function 
if [ ${#nvidiaVoltage} == 1 ]; then
    nvidiaVoltage=" 0$nvidiaVoltage"
fi
if [ ${#nvidiaVoltage} == 2 ]; then
    nvidiaVoltage=" ${nvidiaVoltage} "
fi

if [ ${#nvidiaVoltage} == 3 ]; then
    nvidiaVoltage=" ${nvidiaVoltage}"
fi

if [ ${#nvidiaVoltage} == 4 ]; then
    nvidiaVoltage="${nvidiaVoltage}"
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
        /home/datesli/core_temps_display/connect_arduino.sh &
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

    # Re-apply port settings every loop: other programs (serial monitors,
    # slicers probing for printers) may switch the port to another baud rate
    stty -F "$device" 9600 raw -echo -hupcl 2>/dev/null

    echo $devices > $device
    echo $temps1 > $device
    echo $temps2 > $device
    echo "3:;" > $device

sleep 2
done
    # echo "2:10,10,13,13,;" > $device

