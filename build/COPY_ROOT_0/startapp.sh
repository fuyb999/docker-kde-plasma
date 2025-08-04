#!/bin/bash

# 禁用unicode,chttrans(简繁切换)插件，以解决ctrl+shift+f,ctrl+shift+u快捷键冲突
fcitx5 -d --disable=wayland,unicode,chttrans,cloudpinyin --keep

/usr/bin/xterm