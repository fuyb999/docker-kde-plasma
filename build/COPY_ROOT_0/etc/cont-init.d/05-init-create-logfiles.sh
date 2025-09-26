#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Ensure the files logtail needs to display during init
sudo touch /var/log/{logtail.log,config.log,debug.log,preflight.log,provisioning.log,sync.log}

# vim:ft=sh:ts=4:sw=4:et:sts=4