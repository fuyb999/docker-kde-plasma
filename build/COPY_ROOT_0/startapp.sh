#!/bin/bash

# 禁用unicode,chttrans(简繁切换)插件，以解决ctrl+shift+f,ctrl+shift+u快捷键冲突
if command -v fcitx5; then
  fcitx5 -d --disable=wayland,unicode,chttrans,cloudpinyin --keep
fi
exec ${STARTAPP:-tail -f /dev/null}