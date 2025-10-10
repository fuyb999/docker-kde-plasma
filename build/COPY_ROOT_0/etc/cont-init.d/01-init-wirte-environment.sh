#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.

# Ensure all variables available for interactive sessions
sed -i '7,$d' /opt/aura-dock/etc/environment.sh
while IFS='=' read -r -d '' key val; do
    if [[ $key != "HOME" ]]; then
        env-store "$key"
    fi
done < <(env -0)

# 初始化配置内容
INIT_CONFIG=$(cat <<'EOF'

# First init complete
umask 002
source /opt/aura-dock/etc/environment.sh
nvm use default > /dev/null 2>&1

EOF
)

# 初始化配置函数
init_bashrc_config() {
    local bashrc_file="$1"
    local use_sudo="$2"

    # 检查是否需要初始化
    if [[ ! -f "$bashrc_file" ]]; then
        # 文件不存在，需要初始化
        return 0
    fi

    # 文件存在，检查是否已包含初始化标记
    if $use_sudo grep -q "# First init complete" "$bashrc_file" 2>/dev/null; then
        # 已初始化，不需要再次初始化
        return 1
    else
        # 文件存在但没有初始化标记，需要初始化
        return 0
    fi
}

# 检查是否需要初始化（用于时区设置）
need_first_init() {
    if [ ! -f /root/.bashrc ] || ! sudo grep -q "# First init complete" /root/.bashrc 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 为 root 用户配置
if init_bashrc_config "/root/.bashrc" "sudo"; then
    echo "Initializing /root/.bashrc..."
    echo "$INIT_CONFIG" | sudo tee -a /root/.bashrc > /dev/null
fi

# 设置时区（只在第一次初始化时执行）
if need_first_init; then
    echo "Setting timezone to $TZ..."
    sudo ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" | sudo tee /etc/timezone > /dev/null
fi

# 为当前用户配置
if [[ ! -e "${HOME}/.bashrc" && -f /etc/skel/.bashrc ]]; then
    cp /etc/skel/.bashrc "${HOME}/.bashrc"
    chown "${USER_ID}:${GROUP_ID}" "${HOME}/.bashrc"
elif [[ ! -e "${HOME}/.bashrc" ]]; then
    touch "${HOME}/.bashrc"
    chown "${USER_ID}:${GROUP_ID}" "${HOME}/.bashrc"
fi

# 确保当前用户的 .bashrc 包含初始化配置
if init_bashrc_config "${HOME}/.bashrc" ""; then
    echo "Initializing ${HOME}/.bashrc..."
    echo "$INIT_CONFIG" >> "${HOME}/.bashrc"
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4