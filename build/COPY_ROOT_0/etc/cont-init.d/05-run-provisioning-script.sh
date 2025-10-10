#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.

if [[ -n $PROVISIONING_SCRIPT ]]; then
    file="/opt/aura-dev/bin/provisioning.sh"
    curl -L -o ${file} ${PROVISIONING_SCRIPT}
    if [[ "$?" -eq 0 ]] && [[ `command -v dos2unix` ]]; then
        dos2unix "$file"
        printf "Successfully created %s from %s\n" "$file" "$PROVISIONING_SCRIPT"
    else
        printf "Failed to fetch %s\n" "$PROVISIONING_SCRIPT"
        rm -f $file
    fi
fi

# Provisioning script should create the lock file if it wants to only run once
if [[ ! -e "${HOME}/".update_lock ]]; then
    file="/opt/aura-dev/bin/provisioning.sh"
    printf "Looking for provisioning.sh...\n"
    if [[ ! -f ${file} ]]; then
        printf "Not found\n"
    else
        temp_file=$(mktemp)
        sed "s/^#\!\/bin\/false$/#\!\/bin\/bash/" "$file" > "$temp_file"
        chown "${USER_ID}":${GROUP_ID} "${temp_file}"
        chmod 0755 "${temp_file}"
        if [ $(id -u) -eq 0 ]; then
          su -l "${USER_NAME}" -c "${temp_file}"
        else
          bash -c "${temp_file}"
        fi
        sudo ldconfig
    fi
else
    printf "Refusing to provision container with %s.update_lock present\n" "$HOME"
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4