#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

CONTAINER_INSTANCE_ID_FILE=/.docker-instance/uuid

if [ ! -f "${CONTAINER_INSTANCE_ID_FILE}" ]; then
    echo "creating container instance uuid..."
    sudo mkdir --mode=555 "$(dirname "${CONTAINER_INSTANCE_ID_FILE}")"
    /opt/base/bin/uuidgen | sudo tee "${CONTAINER_INSTANCE_ID_FILE}" > /dev/null
    sudo chmod 444 "${CONTAINER_INSTANCE_ID_FILE}"
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4