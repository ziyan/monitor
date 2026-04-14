#!/bin/bash
set -e

# shellcheck source=/dev/null
source /etc/default/monitor

# wait for display configuration to complete
echo "waiting for display to be ready..."
while [ ! -f /run/monitor/display-ready ]; do
    sleep 1
done
echo "display is ready"

CURSOR_FLAG="-nocursor"
if [ "${MONITOR_SHOW_CURSOR}" = "1" ]; then
    CURSOR_FLAG=""
fi

exec x11vnc -N -display :0 -shared -forever ${CURSOR_FLAG} -xkb -nomodtweak -nopw

