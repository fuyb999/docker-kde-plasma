#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh

mkdir -p /var/run/dbus
mkdir -p /run/dbus  # Ensure /run/dbus directory exists

# Generate machine ID if it doesn't exist
if [ ! -f /var/lib/dbus/machine-id ]; then
    dbus-uuidgen > /var/lib/dbus/machine-id
fi

# Clean up any old sockets
rm -rf /var/${SYSTEM_DBUS_SOCKET:1} \
  ${SYSTEM_DBUS_SOCKET} \
  /run/dbus/pid

# Start system-level D-Bus daemon
echo "Starting system D-Bus daemon..."
dbus-daemon --system --nosyslog --nofork --print-address > /var/run/dbus/system_bus_address 2>&1 &

# Wait for D-Bus socket creation
echo "Waiting for D-Bus socket creation..."
MAX_WAIT=10
count=0
while [ ! -S ${SYSTEM_DBUS_SOCKET} ] && [ $count -lt $MAX_WAIT ]; do
    sleep 1
    count=$((count+1))
    echo "Waiting for D-Bus socket... ($count/$MAX_WAIT)"
done

if [ ! -S ${SYSTEM_DBUS_SOCKET} ]; then
    echo "Error: D-Bus socket was not created"
    exit 1
fi

echo "D-Bus system address: $DBUS_SYSTEM_BUS_ADDRESS"

# Wait for rtkit to start
sleep 2

# Test rtkitctl - 确保完全后台化
rtkitctl --start > /dev/null 2>&1 &

# 确保所有子进程与当前shell分离
disown -a

# vim:ft=sh:ts=4:sw=4:et:sts=4