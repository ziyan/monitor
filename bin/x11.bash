#!/bin/bash
set -e

INSTALL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

function is_x_running
{
    killall -0 xinit > /dev/null 2>&1 || true
}

function kill_x
{
    if is_x_running; then
        killall X Xorg xinit > /dev/null 2>&1 || true
        sleep 3
    fi

    if is_x_running; then
        killall -9 X Xorg xinit > /dev/null 2>&1 || true
    fi

    rm -rf /tmp/.X11-unix /tmp/.X0-lock > /dev/null 2>&1 || true
}

function detect_gpu
{
    if lsmod | grep -q "^nvidia_drm"; then
        echo "nvidia"
    else
        echo "modesetting"
    fi
}

function setup_x
{
    rm -rf /run/monitor/X11
    mkdir -p /run/monitor/X11/Xsession.d
    rsync -ax /etc/X11/Xsession.d/ /run/monitor/X11/Xsession.d/
    rsync -ax "${INSTALL_DIR}/etc/X11/" /run/monitor/X11/

    # determine GPU driver: use config override or auto-detect
    # shellcheck source=/dev/null
    source /etc/default/monitor
    local GPU_DRIVER
    if [ -n "${MONITOR_GPU_DRIVER}" ]; then
        GPU_DRIVER="${MONITOR_GPU_DRIVER}"
        echo "using configured GPU driver: ${GPU_DRIVER}"
    else
        GPU_DRIVER=$(detect_gpu)
        echo "auto-detected GPU driver: ${GPU_DRIVER}"
    fi
    if [ "${GPU_DRIVER}" != "nvidia" ]; then
        rm -f /run/monitor/X11/xorg.conf.d/10-nvidia-custom-mode.conf
    fi
}

# setup clean up trap
trap kill_x SIGHUP SIGINT SIGTERM

# clear display ready signal
rm -f /run/monitor/display-ready

# stop any running x server
kill_x

# setup x server config
setup_x

# start x server
xinit /run/monitor/X11/xinit/xinitrc -- /run/monitor/X11/xinit/xserverrc :0

# cleanup
kill_x

