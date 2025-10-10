#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/aura-dock/etc/environment.sh

ak_file="/root/.ssh/authorized_keys"
if ! sudo ssh-keygen -l -f "$ak_file" > /dev/null 2>&1; then
    echo "Skipping SSH server: No public key" 1>&2
    # No error - Supervisor will not attempt restart
    exec sleep 1
fi

# Dynamically check users - we might have a mounted /etc/passwd
if ! id -u sshd > /dev/null 2>&1; then
    groupadd -r sshd
    useradd -r -g sshd -s /usr/sbin/nologin sshd
fi

printf "Starting SSH server on port ${SSH_PORT}...\n"

fuser -k -SIGKILL 22/tcp > /dev/null 2>&1 &
wait -n

/usr/bin/ssh-keygen -A
/usr/sbin/sshd -D -p 22

# vim:ft=sh:ts=4:sw=4:et:sts=4