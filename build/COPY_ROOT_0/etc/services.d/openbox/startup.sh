#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh
tail -f /dev/null
#if ! command -v fcitx5; then
#  sudo tar -Jxvf /workspace/fcitx5-v5.1.11.tar.xz -C /
#fi
#
#exec fcitx5

# vim:ft=sh:ts=4:sw=4:et:sts=4