#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

#set -e # Exit immediately if a command exits with a non-zero status.

source /opt/ai-dock/etc/environment.sh

rm -rf "$XDG_RUNTIME_DIR"

mkdir -pm700 "$XDG_RUNTIME_DIR"
chown -R ${USER_ID}:${GROUP_ID} "$XDG_RUNTIME_DIR"

# vim:ft=sh:ts=4:sw=4:et:sts=4