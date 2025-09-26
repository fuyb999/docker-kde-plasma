#!/bin/bash

# Must exit and fail to build if any command fails
set -eo pipefail
umask 002

groupadd -g 1111 ai-dock
chown root.ai-dock /opt
chmod g+w /opt
chmod g+s /opt

mkdir -p /opt/environments/{python,javascript}

# Prepare environment for running SSHD
chmod 700 /root
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Remove less relevant parts of motd
rm -f /etc/update-motd.d/10-help-text

# Ensure critical paths/files are present
mkdir -p --mode=0755 /etc/apt/keyrings
mkdir -p --mode=0755 /run/sshd
chown -R root.ai-dock /var/log
chmod -R g+w /var/log
chmod -R g+s /var/log
mkdir -p /var/log/supervisor
mkdir -p /var/empty
mkdir -p /etc/rclone
touch /etc/rclone/rclone.conf

printf "source /opt/ai-dock/etc/environment.sh\n" >> /etc/profile.d/02-ai-dock.sh
printf "source /opt/ai-dock/etc/environment.sh\n" >> /etc/bash.bashrc
printf "ready-test\n" >> /root/.bashrc

#if [[ "$XPU_TARGET" == "NVIDIA_GPU" ]]; then
#    source /opt/ai-dock/bin/build/layer0/nvidia.sh
#elif [[ "$XPU_TARGET" == "AMD_GPU" ]]; then
#    source /opt/ai-dock/bin/build/layer0/amd.sh
#elif [[ "$XPU_TARGET" == "CPU" ]]; then
#    source /opt/ai-dock/bin/build/layer0/cpu.sh
#else
#    printf "No valid XPU_TARGET specified\n" >&2
#    exit 1
#fi

# Give our runtime user full access (added to ai-dock group)
source /opt/ai-dock/bin/build/layer0/clean.sh