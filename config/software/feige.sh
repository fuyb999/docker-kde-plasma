#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh

if [ ! -f "${SOFTWARE_ADDONS_DIR}/Feige_for_64_Linux.tar.gz" ] || [ -n "$(which QIpmsg)" ]; then
  return 0
fi

sudo tar -zxf "${SOFTWARE_ADDONS_DIR}/Feige_for_64_Linux.tar.gz" -C "/usr/local/bin"