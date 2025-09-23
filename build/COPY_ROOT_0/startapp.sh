#!/bin/bash

source /opt/ai-dock/etc/environment.sh

if ! command -v fcitx5; then
  sudo tar -Jxf ${SOFTWARE_ADDONS_DIR}/fcitx5-v5.1.11.tar.xz -C /
fi

if [ ! -d "${XDG_CONFIG_HOME}" ]; then
  sudo cp -r /root/.config "$(basedir $XDG_CONFIG_HOME)"
  sudo chown -R ${USER_ID}:${GROUP_ID} ${XDG_CONFIG_HOME}
fi

# 禁用unicode,chttrans(简繁切换)插件，以解决ctrl+shift+f,ctrl+shift+u快捷键冲突
if command -v fcitx5; then
  fcitx5 --disable=unicode,chttrans -d --keep --verbos 5
fi

exec ${STARTAPP:-tail -f /dev/null}