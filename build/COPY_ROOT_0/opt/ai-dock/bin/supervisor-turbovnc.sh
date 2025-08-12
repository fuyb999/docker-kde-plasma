#!/bin/bash

# Run either an nvidia capable X server or an X proxy

trap cleanup EXIT

SERVICE_NAME="TurboVNC Server"

function cleanup() {
    kill $(jobs -p) > /dev/null 2>&1 &
    wait -n
    sudo rm -rf /tmp/.X* ~/.cache
}

function start() {
    source /opt/ai-dock/etc/environment.sh
    
    if [[ ${SERVERLESS,,} = "true" ]]; then
        printf "Refusing to start $SERVICE_NAME in serverless mode\n"
        exec sleep 10
    fi
    
    printf "Starting ${SERVICE_NAME}...\n"
    
    until [[ -S "$DBUS_SOCKET" ]]; do
        printf "Waiting for dbus socket...\n"
        sleep 1
    done

    mkdir -p ~/.vnc/ ~/.dosbox
     	echo $USER_PASSWORD | /opt/TurboVNC/bin/vncpasswd -f > ~/.vnc/passwd
     	chmod 0600 ~/.vnc/passwd
       /opt/TurboVNC/bin/vncserver ${DISPLAY} \
         -geometry ${DISPLAY_SIZEW}x${DISPLAY_SIZEH} \
         -depth ${DISPLAY_CDEPTH} \
         -auth ~/.vnc/passwd \
         -x509key /opt/caddy/tls/container.key \
         -x509cert /opt/caddy/tls/container.crt

       /usr/bin/openbox --config-file /etc/openbox/rc.xml --startup /opt/TurboVNC/bin/xstartup.turbovnc

       sleep infinity

}

start 2>&1