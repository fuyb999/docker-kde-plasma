#!/bin/bash

trap cleanup EXIT

SERVICE_NAME="Fcitx5"

function cleanup() {
    sudo kill $(jobs -p) > /dev/null 2>&1 &
    wait -n
}

function autostart() {

    fcitx5_autostart_desktop="$(cat << EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
Name=Fctix5
Comment=Launch fctix5 on login
Exec=/usr/bin/fcitx5 %U
Icon=fcitx
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
EOF
    )"

    mkdir -p "${HOME:?}/.config/autostart"
    echo "${fcitx5_autostart_desktop:?}" > "${HOME:?}/.config/autostart/Fcitx5.desktop"
}

function start() {
    source /opt/ai-dock/etc/environment.sh
    if [[ ${SERVERLESS,,} = "true" ]]; then
        printf "Refusing to start $SERVICE_NAME in serverless mode\n"
        exec sleep 10
    fi
    
    printf "Starting ${SERVICE_NAME}...\n"
    
#    until [[ -S "$DBUS_SOCKET" ]]; do
#        printf "Waiting for dbus socket...\n"
#        sleep 1
#    done
    
#    until [ -S "/tmp/.X11-unix/X${DISPLAY/:/}" ]; do
#        printf "Waiting for X11 socket...\n"
#        sleep 1
#    done

    source /opt/ai-dock/etc/environment.sh
   
    # Start FCITX 
#    fcitx -D
    autostart
    exec sleep 10
}

start 2>&1
