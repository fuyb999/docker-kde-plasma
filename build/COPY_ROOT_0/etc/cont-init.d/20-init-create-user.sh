#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -u # Treat unset variables as an error.


# no defined workspace - Keep users close to the install
if [[ -z $WORKSPACE ]]; then
    export WORKSPACE="/opt/"
else
    ws_tmp="/$WORKSPACE/"
    export WORKSPACE=${ws_tmp//\/\//\/}
fi

WORKSPACE_UID=$(stat -c '%u' "$WORKSPACE")
if [[ $WORKSPACE_UID -eq 0 ]]; then
    WORKSPACE_UID=1000
fi
export WORKSPACE_UID

WORKSPACE_GID=$(stat -c '%g' "$WORKSPACE")
if [[ $WORKSPACE_GID -eq 0 ]]; then
    WORKSPACE_GID=1000
fi
export WORKSPACE_GID

if [[ -f "${WORKSPACE}".update_lock ]]; then
    export AUTO_UPDATE=false
fi

if [[ $WORKSPACE != "/opt/" ]]; then
    mkdir -p "${WORKSPACE}"
    chown ${WORKSPACE_UID}.${WORKSPACE_GID} "${WORKSPACE}"
    chmod g+s "${WORKSPACE}"
fi

# Determine workspace mount status
if mountpoint "$WORKSPACE" > /dev/null 2>&1 || [[ $WORKSPACE_MOUNTED == "force" ]]; then
    export WORKSPACE_MOUNTED=true
    mkdir -p "${WORKSPACE}"storage
    mkdir -p "${WORKSPACE}"environments/{python,javascript}
else
    export WORKSPACE_MOUNTED=false
    ln -sT /opt/storage "${WORKSPACE}"storage > /dev/null 2>&1
    no_mount_warning_file="${WORKSPACE}WARNING-NO-MOUNT.txt"
    no_mount_warning="$WORKSPACE is not a mounted volume.\n\nData saved here will not survive if the container is destroyed.\n\n"
    printf "%b" "${no_mount_warning}"
    touch "${no_mount_warning_file}"
    printf "%b" "${no_mount_warning}" > "${no_mount_warning_file}"
    if [[ $WORKSPACE != "/opt/" ]]; then
        printf "Find your software in /opt\n\n" >> "${no_mount_warning_file}"
    fi
fi
# Ensure we have a proper linux filesystem so we don't run into errors on sync
if [[ $WORKSPACE_MOUNTED == "true" ]]; then
    test_file=${WORKSPACE}/.ai-dock-permissions-test
    touch $test_file
    if chown ${WORKSPACE_UID}.${WORKSPACE_GID} $test_file > /dev/null 2>&1; then
        export WORKSPACE_PERMISSIONS=true
    else
        export WORKSPACE_PERMISSIONS=false
    fi
    rm $test_file
fi

# This is a convenience for X11 containers and bind mounts - No additional security implied.
# These are interactive containers; root will always be available. Secure your daemon.

if [[ ${WORKSPACE_MOUNTED,,} == "true" ]]; then
    home_dir=${WORKSPACE}home/${USER_NAME}
    mkdir -p $home_dir
    ln -s $home_dir /home/${USER_NAME}
else
    home_dir=/home/${USER_NAME}
    mkdir -p ${home_dir}
fi
chown ${WORKSPACE_UID}.${WORKSPACE_GID} "$home_dir"
chmod g+s "$home_dir"
groupadd -g $WORKSPACE_GID $USER_NAME
useradd -ms /bin/bash $USER_NAME -d $home_dir -u $WORKSPACE_UID -g $WORKSPACE_GID
printf "%s:%s" "${USER_NAME}" "${USER_PASSWORD}" | chpasswd > /dev/null 2>&1
usermod -a -G $USER_GROUPS $USER_NAME

# For AMD devices - Ensure render group is created if /dev/kfd is present
if ! getent group render >/dev/null 2>&1 && [ -e "/dev/kfd" ]; then
    groupadd -g "$(stat -c '%g' /dev/kfd)" render
    usermod -a -G render $USER_NAME
fi

# May not exist - todo check device ownership
usermod -a -G sgx $USER_NAME
# See the README (in)security notice
printf "%s ALL=(ALL) NOPASSWD: ALL\n" ${USER_NAME} >> /etc/sudoers
sed -i 's/^Defaults[ \t]*secure_path/#Defaults secure_path/' /etc/sudoers
if [[ ! -e ${home_dir}/.bashrc ]]; then
    cp -f /root/.bashrc ${home_dir}
    cp -f /root/.profile ${home_dir}
    chown ${WORKSPACE_UID}:${WORKSPACE_GID} "${home_dir}/.bashrc" "${home_dir}/.profile"
fi
# Set initial keys to match root
if [[ -e /root/.ssh/authorized_keys && ! -d ${home_dir}/.ssh ]]; then
    rm -f ${home_dir}/.ssh
    mkdir -pm 700 ${home_dir}/.ssh > /dev/null 2>&1
    cp -f /root/.ssh/authorized_keys ${home_dir}/.ssh/authorized_keys
    chown -R ${WORKSPACE_UID}:${WORKSPACE_GID} "${home_dir}/.ssh" > /dev/null 2>&1
    chmod 600 ${home_dir}/.ssh/authorized_keys > /dev/null 2>&1
    if [[ $WORKSPACE_MOUNTED == 'true' && $WORKSPACE_PERMISSIONS == 'false' ]]; then
        mkdir -pm 700 "/home/${USER_NAME}-linux"
        printf "StrictModes no\n" > /etc/ssh/sshd_config.d/no-strict.conf
    fi
fi

# Set username in startup sctipts
#sed -i "s/\$USER_NAME/$USER_NAME/g" /etc/supervisor/supervisord/conf.d/*

# vim:ft=sh:ts=4:sw=4:et:sts=4