#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh

if [ ! -f "${SOFTWARE_ADDONS_DIR}/flix-1.8.1+57-linux.deb" ] || [ -n "$(which flix)" ]; then
  return 0
fi

sudo dpkg -i ${SOFTWARE_ADDONS_DIR}/flix-1.8.1+57-linux.deb