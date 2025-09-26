#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

sudo mkdir -m 2770 -p /run/http_ports
sudo chown root.ai-dock /run/http_ports
sudo mkdir -p /opt/caddy/etc

# vim:ft=sh:ts=4:sw=4:et:sts=4