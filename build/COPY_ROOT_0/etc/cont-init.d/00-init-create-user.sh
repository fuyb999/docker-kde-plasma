#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# 设置用户和组 ID
export USER_ID=${USER_ID:-1000}
export GROUP_ID=${GROUP_ID:-1000}

# 创建用户和组
export HOME=${HOME:-"/home/${USER_NAME}"}

# 检查组是否已存在，如果不存在则创建
if ! getent group $USER_NAME > /dev/null 2>&1; then
    groupadd -g $GROUP_ID $USER_NAME
else
    # 如果组已存在，确保其 GID 正确
    existing_gid=$(getent group $USER_NAME | cut -d: -f3)
    if [ "$existing_gid" != "$GROUP_ID" ]; then
        groupmod -g $GROUP_ID $USER_NAME
    fi
fi

# 检查用户是否已存在
if id -u $USER_NAME > /dev/null 2>&1; then
    # 用户已存在，确保其 UID 和 GID 正确
    existing_uid=$(id -u $USER_NAME)
    existing_gid=$(id -g $USER_NAME)

    if [ "$existing_uid" != "$USER_ID" ] || [ "$existing_gid" != "$GROUP_ID" ]; then
        sudo usermod -u $USER_ID -g $GROUP_ID $USER_NAME
    fi
else
    # 用户不存在，创建用户
    useradd -ms /bin/bash $USER_NAME -d $HOME -u $USER_ID -g $GROUP_ID > /dev/null
    printf "%s:%s" "${USER_NAME}" "${USER_PASSWORD}" | chpasswd > /dev/null 2>&1
fi

# 确保家目录所有权正确
chown ${USER_ID}:${GROUP_ID} "${HOME}"

# 添加用户到 + 组
sudo usermod -a -G $USER_GROUPS $USER_NAME

# 可能不存在的组 - 添加用户到 sgx 组（如果存在）
if getent group sgx > /dev/null 2>&1; then
    sudo usermod -a -G sgx $USER_NAME
fi

# 配置 sudo 权限
if ! sudo grep -q "^${USER_NAME} ALL" /etc/sudoers; then
    echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null
fi

sudo sed -i 's/^Defaults[ \t]*secure_path/#Defaults secure_path/' /etc/sudoers

# vim:ft=sh:ts=4:sw=4:et:sts=4