#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.

if sudo test -f "/root/.ssh/authorized_keys_mount"; then
  sudo cat /root/.ssh/authorized_keys_mount | sudo tee /root/.ssh/authorized_keys > /dev/null
fi

# Named to avoid conflict with the cloud providers below

if [[ -n $SSH_PUBKEY ]]; then
    echo "$SSH_PUBKEY" | sudo tee -a /root/.ssh/authorized_keys > /dev/null
fi

# Alt names for $SSH_PUBKEY
# runpod.io
if [[ -n $PUBLIC_KEY ]]; then
    echo "$PUBLIC_KEY" | sudo tee -a /root/.ssh/authorized_keys > /dev/null
fi

# vast.ai
if [[ -n $SSH_PUBLIC_KEY ]]; then
    echo "$SSH_PUBLIC_KEY" | sudo tee -a /root/.ssh/authorized_keys > /dev/null
fi

# 设置正确的权限
sudo chmod 600 /root/.ssh/authorized_keys

# 设置 SSH 密钥
if [[ -e /root/.ssh/authorized_keys && ! -d ${HOME}/.ssh ]]; then
    rm -f ${HOME}/.ssh
    mkdir -pm 700 ${HOME}/.ssh > /dev/null 2>&1
    sudo cp -f /root/.ssh/authorized_keys ${HOME}/.ssh/authorized_keys
    sudo chown -R ${USER_ID}:${GROUP_ID} "${HOME}/.ssh" > /dev/null 2>&1
    chmod 600 ${HOME}/.ssh/authorized_keys > /dev/null 2>&1
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4