# Monitor

Kiosk system for TV displays. Runs Chromium in fullscreen with automatic tab rotation and remote control via VNC.

## Overview

Designed for headless mini-PCs connected to TVs. Supervisor manages three services:

- **x11** - X server with auto-detected GPU driver (nvidia/modesetting) and display mode
- **chromium** - fullscreen kiosk browser with a tab rotation extension
- **vncserver** - x11vnc for remote viewing and control

## Installation

Install dependencies (Debian):

```bash
apt-get install chromium x11vnc supervisor xinit rsync sudo mesa-utils
```

For nvidia GPU, also install:

```bash
apt-get install nvidia-kernel-dkms nvidia-driver firmware-misc-nonfree
```

Deploy and run the install script:

```bash
rsync -ax --progress --delete ./ <host>:/opt/monitor/
ssh <host> /opt/monitor/bin/install.bash
```

The install script creates the monitor user, log directory, generates the supervisor config, and symlinks it. It also installs `/etc/default/monitor` with defaults if not already present.

Disable lid switch (for laptops):

```
# /etc/systemd/logind.conf
HandleLidSwitch=ignore
```

## Deployment

Deploy to a machine via rsync, then re-run install to regenerate the supervisor config:

```bash
rsync -ax --progress --delete ./ <host>:/opt/monitor/
ssh <host> /opt/monitor/bin/install.bash
ssh <host> supervisorctl restart monitor:
```

## Configuration

All per-deployment settings live in `/etc/default/monitor` on each machine. This file is created by `install.bash` on first run and is not overwritten by subsequent installs.

After changing `/etc/default/monitor`, re-run `install.bash` to regenerate the supervisor config, then restart services.

| Variable | Default | Description |
|---|---|---|
| `MONITOR_LOG_DIR` | `/var/log/monitor` | Log directory |
| `MONITOR_SHOW_CURSOR` | `0` | Set to `1` to show mouse cursor on screen and VNC |
| `MONITOR_GPU_DRIVER` | auto-detect | Force `nvidia` or `modesetting` |
| `MONITOR_MODE_NAME` | (empty) | Custom display mode name for xrandr |
| `MONITOR_MODE` | (empty) | Custom modeline, leave empty for display's preferred mode |
| `MONITOR_FRAMEBUFFER` | (empty) | Force framebuffer size, e.g. `1920x1080` |
| `MONITOR_XRANDR_ARGS` | `--pos 0x0` | Extra xrandr output arguments |
| `MONITOR_URLS` | (empty) | URLs to cycle through, one per line |
| `MONITOR_SWITCH_INTERVAL` | `30` | Tab switching interval in seconds |

Example with a custom modeline for a TV without proper EDID:

```bash
MONITOR_MODE_NAME="television"
MONITOR_MODE="173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync"
MONITOR_FRAMEBUFFER="1920x1080"
```

## Keyboard Shortcuts

- **Alt+P** - pause/resume tab rotation (via VNC)

## Logs

Log directory defaults to `/var/log/monitor`, configurable via `MONITOR_LOG_DIR`.

```bash
tail -f /var/log/monitor/x11.log
tail -f /var/log/monitor/chromium.log
tail -f /var/log/monitor/vncserver.log
```
