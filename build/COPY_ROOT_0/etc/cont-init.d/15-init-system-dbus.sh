#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/aura-dock/etc/environment.sh

if [[ ${SERVERLESS,,} = "true" ]]; then
    printf "Refusing to start system dbus in serverless mode\n"
    exit 0
fi

if ! command -v dbus-uuidgen > /dev/null; then
  exit 0
fi

sudo mkdir -pm777 /var/run/dbus
sudo mkdir -pm777 /run/dbus  # Ensure /run/dbus directory exists

# Generate machine ID if it doesn't exist
if [ ! -f /var/lib/dbus/machine-id ]; then
   dbus-uuidgen | tee /var/lib/dbus/machine-id > /dev/null
fi

# Clean up any old sockets
rm -rf /var/${SYSTEM_DBUS_SOCKET:1} \
  ${SYSTEM_DBUS_SOCKET} \
  /run/dbus/pid

# Start system-level D-Bus daemon
echo "Starting system D-Bus daemon..."
# 直接启动 dbus-daemon 并重定向
dbus-daemon --system --nosyslog --nofork --print-address > /var/run/dbus/system_bus_address 2>&1 &
DBUS_PID=$!

# Wait for D-Bus socket creation
echo "Waiting for D-Bus socket creation..."
MAX_WAIT=10
count=0
while [ ! -S "${SYSTEM_DBUS_SOCKET}" ] && [ $count -lt $MAX_WAIT ]; do
    sleep 1
    count=$((count+1))
    echo "Waiting for D-Bus socket... ($count/$MAX_WAIT)"
done

if [ ! -S "${SYSTEM_DBUS_SOCKET}" ]; then
    echo "Error: D-Bus socket was not created"
    sudo kill $DBUS_PID 2>/dev/null
    exit 1
fi

echo "D-Bus system address: $(cat /var/run/dbus/system_bus_address)"

# Wait for rtkit to start
sleep 2

# Test rtkitctl
rtkitctl --start > /dev/null 2>&1 &

# 立即分离所有后台作业
disown -a

echo "Services started in background"

# vim:ft=sh:ts=4:sw=4:et:sts=4