#!/bin/bash
set -e

INSTALL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# check required dependencies
REQUIRED_PACKAGES="chromium x11vnc supervisor xinit rsync sudo"
MISSING_PACKAGES=""
for PACKAGE in ${REQUIRED_PACKAGES}; do
    if ! dpkg -s "${PACKAGE}" >/dev/null 2>&1; then
        MISSING_PACKAGES="${MISSING_PACKAGES} ${PACKAGE}"
    fi
done
if [ -n "${MISSING_PACKAGES}" ]; then
    echo "missing required packages:${MISSING_PACKAGES}"
    echo "install them with: apt-get install${MISSING_PACKAGES}"
    exit 1
fi

# install default config if not present
if [ ! -f /etc/default/monitor ]; then
    cp "${INSTALL_DIR}/etc/default/monitor" /etc/default/monitor
    echo "installed default config to /etc/default/monitor"
fi

# source config
# shellcheck source=/dev/null
source /etc/default/monitor

# create log directory
mkdir -p "${MONITOR_LOG_DIR}"
echo "log directory: ${MONITOR_LOG_DIR}"

# generate supervisor config from template
TEMPLATE="${INSTALL_DIR}/etc/supervisor/conf-available.d/monitor.conf.in"
GENERATED="${INSTALL_DIR}/etc/supervisor/conf-available.d/monitor.conf"
sed -e "s|@@INSTALL_DIR@@|${INSTALL_DIR}|g" -e "s|@@MONITOR_LOG_DIR@@|${MONITOR_LOG_DIR}|g" "${TEMPLATE}" > "${GENERATED}"
echo "generated supervisor config: ${GENERATED}"

# symlink supervisor config
SUPERVISOR_LINK="/etc/supervisor/conf.d/monitor.conf"
ln -sf "${GENERATED}" "${SUPERVISOR_LINK}"
echo "symlinked supervisor config to ${SUPERVISOR_LINK}"

# create monitor user if not exists
if ! id -u monitor >/dev/null 2>&1; then
    useradd -m -U -s /bin/false monitor
    echo "created monitor user"
fi

echo "install complete"
