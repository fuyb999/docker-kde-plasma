#!/bin/bash

trap cleanup EXIT

function cleanup() {
    fuser -k -SIGTERM ${SSH_PORT_HOST}/tcp > /dev/null 2>&1 &
    wait -n
}

function start() {
    source /opt/aura-dev/etc/environment.sh

    ak_file="/root/.ssh/authorized_keys"
    if [[ -f "$ak_file" ]] && [[ ! $(ssh-keygen -l -f $ak_file) ]]; then
        printf "Skipping SSH server: No public key\n" 1>&2
        # No error - Supervisor will not atempt restart
        exec sleep 6
    fi

    # Dynamically check users - we might have a mounted /etc/passwd
    if ! id -u sshd > /dev/null 2>&1; then
        groupadd -r sshd
        useradd -r -g sshd -s /usr/sbin/nologin sshd
    fi

    printf "Starting SSH server on port ${SSH_PORT_HOST}...\n"

    fuser -k -SIGKILL ${SSH_PORT_HOST}/tcp > /dev/null 2>&1 &
    wait -n

    /usr/bin/ssh-keygen -A
    /usr/sbin/sshd -D -p ${SSH_PORT_HOST}
}

start 2>&1
