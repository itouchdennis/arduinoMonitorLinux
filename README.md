# arduinoMonitorLinux

Shows live PC hardware stats (CPU/GPU temperature, usage, RAM, water temperature, time) on an Arduino TFT display, fed from Linux over USB serial.

My setup:
- EndeavourOS
- Intel Core i5 12600K
- AMD Radeon RX 9070 XT (older versions of `senddata.sh` used an Nvidia RTX 3070 Ti via `nvidia-smi`)
- Arduino with an MCUFRIEND TFT shield

## Repository layout

| Path | Content |
|---|---|
| `pcHwMon/` | Arduino sketch (`pcHwMon.ino`) and display icons (`pics.h`) |
| `core_temps_display/connect_arduino.sh` | Opens the serial connection (9600 baud) to the first `/dev/ttyUSB*` or `/dev/ttyACM*` and reconnects if it drops |
| `core_temps_display/senddata.sh` | Reads sensor values every 2 seconds and sends them to the Arduino |
| `core_temps_display/arduino_watchdog.sh` | Optional: restarts `arduino-connect.service` if `/dev/arduino` disappears or stops responding |
| `core_temps_display/start.sh`, `connect.sh`, `stop_connect.sh` | Old manual start/stop helpers (not needed with systemd) |
| `systemd/` | systemd units `arduino-connect.service` and `arduino-data.service` |
| `udev/99-arduino.rules` | udev rule that creates `/dev/arduino` for the CH340 USB serial chip |

## Installation

### 1. Flash the Arduino

1. Open `pcHwMon/pcHwMon.ino` in the Arduino IDE.
2. Install the libraries **Adafruit GFX Library** and **MCUFRIEND_kbv** via the Library Manager.
3. Select your board/port and upload.

### 2. Install dependencies (Linux)

```bash
# Arch / EndeavourOS
sudo pacman -S lm_sensors jq procps-ng
yay -S amdgpu_top          # GPU voltage and VRAM usage (AMD)
sudo sensors-detect        # once, to set up the sensor modules
```

Check that `sensors` shows `Package id 0:` (CPU), `junction:` (GPU) and, if you have one, `External sensor:` (water). Adjust the `grep` patterns in `senddata.sh` if your sensor names differ.

### 3. Copy the scripts

The systemd units expect the scripts in `/home/datesli/core_temps_display/`. Either use the same path or change `ExecStart`/`ExecStop`/`User` in the unit files and the path in `senddata.sh`.

```bash
git clone https://github.com/itouchdennis/arduinoMonitorLinux.git
cd arduinoMonitorLinux
cp -r core_temps_display ~/
chmod +x ~/core_temps_display/*.sh
```

Also adjust `deviceNames` at the top of `senddata.sh` to the names you want shown for your CPU and GPU.

### 4. udev rule (optional, needed for the watchdog)

The rule matches the CH340 chip (`1a86:7523`) found on most Arduino Nano/Uno clones. Check yours with `lsusb` and adjust the IDs if needed.

```bash
sudo cp udev/99-arduino.rules /etc/udev/rules.d/
sudo groupadd -f arduino
sudo usermod -aG arduino $USER   # log out and back in afterwards
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Your user also needs access to the serial device (`uucp` group on Arch):

```bash
sudo usermod -aG uucp $USER
```

### 5. Install and enable the services

```bash
sudo cp systemd/arduino-connect.service systemd/arduino-data.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now arduino-connect.service arduino-data.service
```

`arduino-connect` keeps the serial port open (otherwise the Arduino resets on every write). `arduino-data` runs `senddata.sh` as root and pushes the values.

## Usage

Once the services are running, the display updates automatically every 2 seconds, also after a reboot.

```bash
# Status
systemctl status arduino-connect arduino-data

# Live logs
journalctl -fu arduino-connect -u arduino-data

# Restart after changing a script
sudo systemctl restart arduino-connect arduino-data

# Stop
sudo systemctl stop arduino-data arduino-connect
```

Run the watchdog manually (as root, since it restarts a service):

```bash
sudo ~/core_temps_display/arduino_watchdog.sh
```

### Testing without the services

```bash
~/core_temps_display/connect_arduino.sh &   # open the connection
sudo ~/core_temps_display/senddata.sh       # send data, Ctrl+C to stop
```

`stop_connect.sh` ends the connection, but note it runs `killall tail` and so kills **every** `tail` process.

### Serial protocol

`senddata.sh` sends four lines per update:

```
0: <CPU vendor>, <CPU model>, <GPU vendor>, <GPU model>,;
1:<cpuTemp>,<cpuUsage>,<ramUsage>,<HH:MM>,;
2:<gpuTemp>,<gpuUsage/VRAM %>,<gpuVoltage>,<waterTemp>,;
3:;
```

## Credits

The original Arduino project and idea come from https://www.instructables.com/PC-Hardware-Monitor/, check it out!
