#!/bin/bash
set -e

INSTALL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=/dev/null
source /etc/default/monitor

export HOME="/home/monitor"
export DISPLAY=:0

# wait for display configuration to complete
echo "waiting for display to be ready..."
while [ ! -f /run/monitor/display-ready ]; do
    sleep 1
done
echo "display is ready"

# auto-detect screen resolution from current X screen, fall back to config or default
if [ -n "${MONITOR_FRAMEBUFFER}" ]; then
    SCREEN_SIZE="${MONITOR_FRAMEBUFFER}"
else
    SCREEN_SIZE=$(xrandr 2>/dev/null | awk '/^Screen.*current/{printf "%dx%d", $8, $10}')
fi
SCREEN_SIZE="${SCREEN_SIZE:-1920x1080}"
WINDOW_WIDTH="${SCREEN_SIZE%x*}"
WINDOW_HEIGHT="${SCREEN_SIZE#*x}"

function kill() {
    for _ in {1..10}; do
        killall -0 chromium >/dev/null 2>&1 || break
        sleep 1
        killall chromium >/dev/null 2>&1 || true
    done

    while true; do
        killall -0 chromium >/dev/null 2>&1 || break
        sleep 1
        killall -9 chromium >/dev/null 2>&1 || true
    done
}

# clean up
kill

# wait a bit
sleep 3

# clear extension service worker cache to pick up code changes without wiping localStorage
rm -rf ${HOME}/.config/chromium/Default/Service\ Worker >/dev/null 2>&1 || true
rm -rf ${HOME}/.config/chromium/Default/Extensions >/dev/null 2>&1 || true

# restart in a while
# {
#     sleep 10
#
#     # wait one hour
#     for I in {1..3600}; do
#         killall -0 chromium >/dev/null 2>&1 || break
#         sleep 1
#     done
#
#     # stop process
#     kill
# } &

# generate extension config from /etc/default/monitor
EXTENSION_CONFIG="${INSTALL_DIR}/chromium/monitor/config.json"
URLS_JSON=$(echo "${MONITOR_URLS}" | awk 'NF{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$0); printf "%s\"%s\"", SEP, $0; SEP=","}' | sed 's/^/[/;s/$/]/')
printf '{"urls":%s,"intervalSeconds":%d}\n' "${URLS_JSON:-[]}" "${MONITOR_SWITCH_INTERVAL:-30}" > "${EXTENSION_CONFIG}"
echo "extension config: $(cat "${EXTENSION_CONFIG}")"

chown -R monitor:monitor "${INSTALL_DIR}/chromium"

exec sudo -n -E -u monitor chromium \
    --noerrdialogs \
    --no-first-run \
    --disable-dev-shm-usage \
    --no-default-browser-check \
    --kiosk \
    --disable-pinch \
    --overscroll-history-navigation=0 \
    --window-position=0,0 \
    --window-size="${WINDOW_WIDTH},${WINDOW_HEIGHT}" \
    --start-fullscreen \
    --ignore-certificate-errors \
    --no-sandbox \
    --disable-pinch \
    --homedir=${HOME} \
    --load-extension="${INSTALL_DIR}/chromium/monitor" \
    --enable-features=OverlayScrollbar,OverlayScrollbarFlashAfterAnyScrollUpdate,OverlayScrollbarFlashWhenMouseEnter,WebUIDarkMode \
    --force-dark-mode \
    --default-background-color=FF000000 \
    --enable-logging=stderr \
    --log-level=0 \
    --v=1 \
    --log-file=/dev/stderr \
    --disable-hang-monitor

