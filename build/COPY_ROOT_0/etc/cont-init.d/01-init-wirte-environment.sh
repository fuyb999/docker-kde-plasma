#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.

 # Ensure all variables available for interactive sessions
sed -i '7,$d' /opt/ai-dock/etc/environment.sh
while IFS='=' read -r -d '' key val; do
    if [[ $key != "HOME" ]]; then
        env-store "$key"
    fi
done < <(env -0)

if [ ! -f /root/.bashrc ] || ! sudo grep -q "# First init complete" /root/.bashrc; then
    echo "# First init complete" | sudo tee -a /root/.bashrc > /dev/null
    echo "umask 002" | sudo tee -a /root/.bashrc > /dev/null
    echo "source /opt/ai-dock/etc/environment.sh" | sudo tee -a /root/.bashrc > /dev/null
    echo "nvm use default > /dev/null 2>&1" | sudo tee -a /root/.bashrc > /dev/null
    sudo ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" | sudo tee /etc/timezone > /dev/null
fi

# 设置 bashrc 和 profile
if [[ -f /root/.bashrc && ! -e ${HOME}/.bashrc ]]; then
    sudo cp -f /root/.bashrc ${HOME}
    sudo cp -f /root/.profile ${HOME}
    sudo chown ${USER_ID}:${GROUP_ID} "${HOME}/.bashrc" "${HOME}/.profile"
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4