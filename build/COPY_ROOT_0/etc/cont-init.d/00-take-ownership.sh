#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

sudo chown ${USER_ID}:${GROUP_ID} ${HOME}
sudo chown -R ${USER_ID}:ai-dock \
     /opt/ai-dock \
     ${XDG_SOFTWARE_HOME:-/opt/apps} \
     ${XDG_ADDONS_HOME:-/opt/addons}

# vim:ft=sh:ts=4:sw=4:et:sts=4