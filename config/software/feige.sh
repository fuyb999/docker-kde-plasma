#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/aura-dev/etc/environment.sh

if [ ! -f "${SOFTWARE_ADDONS_DIR}/Feige_for_64_Linux.tar.gz" ] || [ -n "$(which QIpmsg)" ]; then
  return 0
fi

sudo tar -zxf "${SOFTWARE_ADDONS_DIR}/Feige_for_64_Linux.tar.gz" -C "/usr/local/bin"

config_dir="$HOME/.feige"
config_file="$config_dir/.configIpmsg"
[ -d "$config_dir" ] || mkdir "$config_dir"

mac_address="$(ifconfig | grep ether | awk '{print $2}')}"

echo "$USER_NAME" > "$config_file"
echo "2425" >> "$config_file"
echo "1" >> "$config_file"
echo "WorkGroup" >> "$config_file"
echo "$mac_address" >> "$config_file"
