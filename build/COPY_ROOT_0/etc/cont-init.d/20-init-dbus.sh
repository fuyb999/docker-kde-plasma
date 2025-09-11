#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

#set -e # Exit immediately if a command exits with a non-zero status.

source /opt/ai-dock/etc/environment.sh
mkdir -pm700 "$XDG_RUNTIME_DIR"
chown $(id -u):$(id -u) "$XDG_RUNTIME_DIR"

groupadd fuse && \
    usermod -a -G fuse ${USER_NAME}

mkdir -p $XDG_RUNTIME_DIR/doc
chmod 1777 $XDG_RUNTIME_DIR/doc

# vim:ft=sh:ts=4:sw=4:et:sts=4