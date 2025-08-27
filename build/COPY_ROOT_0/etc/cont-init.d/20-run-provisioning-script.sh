#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

#set -e # Exit immediately if a command exits with a non-zero status.

if [[ -n  $PROVISIONING_SCRIPT ]]; then
    file="/opt/ai-dock/bin/provisioning.sh"
    curl -L -o ${file} ${PROVISIONING_SCRIPT}
    if [[ "$?" -eq 0 ]]; then
        dos2unix "$file"
        sed -i "s/^#\!\/bin\/false$/#\!\/bin\/bash/" "$file"
        printf "Successfully created %s from %s\n" "$file" "$PROVISIONING_SCRIPT"
    else
        printf "Failed to fetch %s\n" "$PROVISIONING_SCRIPT"
        rm -f $file
    fi
fi

# Provisioning script should create the lock file if it wants to only run once
if [[ ! -e "$WORKSPACE"/.update_lock ]]; then
    file="/opt/ai-dock/bin/provisioning.sh"
    printf "Looking for provisioning.sh...\n"
    if [[ ! -f ${file} ]]; then
        printf "Not found\n"
    else
        chown "${USER_NAME}":ai-dock "${file}"
        chmod 0755 "${file}"
        su -l "${USER_NAME}" -c "${file}"
        ldconfig
    fi
else
    printf "Refusing to provision container with %s.update_lock present\n" "$WORKSPACE"
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4