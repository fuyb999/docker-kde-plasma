#!/bin/bash

# Must exit and fail to build if any command fails
set -eo pipefail
umask 002

groupadd -g ${USER_ID} ${USER_GROUP_NAME}
chown ${USER_ID}.${USER_GROUP_NAME} /opt
chmod g+w /opt
chmod g+s /opt

# 配置sudo允许${USER_NAME}组成员免密码执行命令
echo "%${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USER_NAME}
chmod 440 /etc/sudoers.d/${USER_NAME}

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
chown -R root.aura-dev /var/log
chmod -R g+w /var/log
chmod -R g+s /var/log
mkdir -p /var/log/supervisor
mkdir -p /var/empty

printf "source /opt/aura-dev/etc/environment.sh\n" >> /etc/profile.d/02-aura-dev.sh
printf "source /opt/aura-dev/etc/environment.sh\n" >> /etc/bash.bashrc
printf "ready-test\n" >> /root/.bashrc

# Give our runtime user full access (added to aura-dev group)
source /opt/aura-dev/bin/build/layer0/clean.sh