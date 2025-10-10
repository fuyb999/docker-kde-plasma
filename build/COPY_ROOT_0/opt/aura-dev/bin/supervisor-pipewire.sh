#!/bin/bash

trap cleanup EXIT

SERVICE_NAME="Pipewire"

function cleanup() {
    kill $(jobs -p) > /dev/null 2>&1
    wait -n
}

function start() {
    source /opt/aura-dev/etc/environment.sh
    if [[ ${SERVERLESS,,} = "true" ]]; then
        printf "Refusing to start $SERVICE_NAME in serverless mode\n"
        exec sleep 10
    fi

    if [[ ${SELKIES_ENABLED,,} != "true" ]]; then
        printf "Refusing to start $SERVICE_NAME without SELKIES_ENABLED=true\n"
        exec sleep 10
    fi

    printf "Starting ${SERVICE_NAME}...\n"
    
    until [ -S "/tmp/.X11-unix/X${DISPLAY/:/}" ]; do
        printf "Waiting for X11 socket...\n"
        sleep 1
    done

    source /opt/aura-dev/etc/environment.sh

    /usr/bin/pipewire   
}

start 2>&1