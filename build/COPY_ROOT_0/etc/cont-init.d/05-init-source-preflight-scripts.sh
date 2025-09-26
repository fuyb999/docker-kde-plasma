#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

sudo chown -R ${USER_ID}:${GROUP_ID} /opt/ai-dock/etc/

preflight_dir="/opt/ai-dock/bin/preflight.d"
printf "Looking for scripts in %s...\n" "$preflight_dir"
for script in /opt/ai-dock/bin/preflight.d/*.sh; do
  source "$script";
done


# vim:ft=sh:ts=4:sw=4:et:sts=4