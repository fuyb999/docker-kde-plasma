#!/bin/bash

# Run either an nvidia capable X server or an X proxy

trap cleanup EXIT

SERVICE_NAME="X Server"

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
    
    cleanup
    
    if [[ $XPU_TARGET == "NVIDIA_GPU"  && $(is_nvidia_capable) == "true" && ${ACCEPT_NVIDIA_LICENSE,,} != "false" ]]; then
        printf "Installing NVIDIA drivers...\n"
        start_nvidia
    else
        start_proxy
    fi
}

function start_nvidia() {
    # Mostly copied from https://github.com/selkies-project/docker-nvidia-glx-desktop

    # Check if nvidia display drivers are present - Download if not
    if ! which nvidia-xconfig /dev/null 2>&1; then
        # Driver version is provided by the kernel through the container toolkit
        export DRIVER_ARCH="$(dpkg --print-architecture | sed -e 's/arm64/aarch64/'  -e 's/i.*86/x86/' -e 's/amd64/x86_64/' -e 's/unknown/x86_64/')"
        export DRIVER_VERSION="$(head -n1 </proc/driver/nvidia/version | awk '{print $8}')"
        # Download the correct nvidia driver (check multiple locations)
        cd /tmp
        curl -fsSL -O "https://international.download.nvidia.com/XFree86/Linux-${DRIVER_ARCH}/${DRIVER_VERSION}/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run" || curl -fsSL -O "https://international.download.nvidia.com/tesla/${DRIVER_VERSION}/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run" || { echo "Failed NVIDIA GPU driver download."; }
        
        if [ -f "/tmp/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run" ]; then
            # Extract installer before installing
            sudo sh "NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run" -x
            cd "NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}"
            # Run installation without the kernel modules and host components
            sudo ./nvidia-installer --silent \
                            --no-kernel-module \
                            --install-compat32-libs \
                            --no-nouveau-check \
                            --no-nvidia-modprobe \
                            --no-rpms \
                            --no-backup \
                            --no-check-for-alternate-installs
            sudo rm -rf /tmp/NVIDIA* && cd ~
        fi
    fi

    start_proxy
}


#
# Setup selection criterias of the main window.
#

APP_DEF_NAME=
APP_DEF_CLASS=
APP_DEF_GROUP_NAME=
APP_DEF_GROUP_CLASS=
APP_DEF_ROLE=
APP_DEF_TITLE=
APP_DEF_TYPE=

set_app_def_vars() {
    f="$1"

    APP_DEF_NAME="$(awk -F "[><]" '/Name/{print $3}' < "${f}")"
    APP_DEF_CLASS="$(awk -F "[><]" '/Class/{print $3}' < "${f}")"
    APP_DEF_GROUP_NAME="$(awk -F "[><]" '/GroupName/{print $3}' < "${f}")"
    APP_DEF_GROUP_CLASS="$(awk -F "[><]" '/GroupClass/{print $3}' < "${f}")"
    APP_DEF_ROLE="$(awk -F "[><]" '/Role/{print $3}' < "${f}")"
    APP_DEF_TITLE="$(awk -F "[><]" '/Title/{print $3}' < "${f}")"
    APP_DEF_TYPE="$(awk -F "[><]" '/Type/{print $3}' < "${f}")"

    # If using the JWM config, remove the begining `^` and ending `$` regex
    # characters, because they are not supported by Openbox.
    if [ "${f}" = /etc/jwm/main-window-selection.jwmrc ]; then
        APP_DEF_NAME="$(echo "${APP_DEF_NAME}" | sed 's/^\^//' | sed 's/\$$//')"
        APP_DEF_CLASS="$(echo "${APP_DEF_CLASS}" | sed 's/^\^//' | sed 's/\$$//')"
        APP_DEF_GROUP_NAME="$(echo "${APP_DEF_GROUP_NAME}" | sed 's/^\^//' | sed 's/\$$//')"
        APP_DEF_GROUP_CLASS="$(echo "${APP_DEF_GROUP_CLASS}" | sed 's/^\^//' | sed 's/\$$//')"
        APP_DEF_ROLE="$(echo "${APP_DEF_ROLE}" | sed 's/^\^//' | sed 's/\$$//')"
        APP_DEF_TITLE="$(echo "${APP_DEF_TITLE}" | sed 's/^\^//' | sed 's/\$$//')"
        APP_DEF_TYPE="$(echo "${APP_DEF_TYPE}" | sed 's/^\^//' | sed 's/\$$//')"
    fi
}

# If /dev/dri is not available in te container we will have no HW accel
function start_proxy() {
    echo "proxy" > /tmp/.X-mode
#    /usr/bin/Xvfb "${DISPLAY}" -screen 0 "8192x4096x${DISPLAY_CDEPTH}" -dpi "${DISPLAY_DPI}" +extension "COMPOSITE" +extension "DAMAGE" +extension "GLX" +extension "RANDR" +extension "RENDER" +extension "MIT-SHM" +extension "XFIXES" +extension "XTEST" +iglx +render -nolisten "tcp" -ac -noreset -shmem

    if [ -f /etc/openbox/main-window-selection.xml ]; then
        set_app_def_vars /etc/openbox/main-window-selection.xml
    elif [ -f /etc/jwm/main-window-selection.jwmrc ]; then
        set_app_def_vars /etc/jwm/main-window-selection.jwmrc
    else
        APP_DEF_TYPE=normal
    fi

    # Generate matching criterias.
    CRITERIAS=
    if [ -n "${APP_DEF_NAME}" ]; then
        CRITERIAS="${CRITERIAS} name=\"${APP_DEF_NAME}\""
    fi
    if [ -n "${APP_DEF_CLASS}" ]; then
        CRITERIAS="${CRITERIAS} class=\"${APP_DEF_CLASS}\""
    fi
    if [ -n "${APP_DEF_GROUP_NAME}" ]; then
        CRITERIAS="${CRITERIAS} groupname=\"${APP_DEF_GROUP_NAME}\""
    fi
    if [ -n "${APP_DEF_GROUP_CLASS}" ]; then
        CRITERIAS="${CRITERIAS} groupclass=\"${APP_DEF_GROUP_CLASS}\""
    fi
    if [ -n "${APP_DEF_ROLE}" ]; then
        CRITERIAS="${CRITERIAS} role=\"${APP_DEF_ROLE}\""
    fi
    if [ -n "${APP_DEF_TITLE}" ]; then
        CRITERIAS="${CRITERIAS} title=\"${APP_DEF_TITLE}\""
    fi
    if [ -n "${APP_DEF_TYPE}" ]; then
        CRITERIAS="${CRITERIAS} type=\"${APP_DEF_TYPE}\""
    fi

    # Write the final Openbox config file.
    sed "s/%MAIN_APP_WINDOW_MATCH_CRITERIAS%/${CRITERIAS}/" < /etc/openbox/rc.xml.template > /var/run/openbox/rc.xml

    mkdir -p ~/.vnc/ ~/.dosbox
  	echo $USER_PASSWORD | /opt/TurboVNC/bin/vncpasswd -f > ~/.vnc/passwd
  	chmod 0600 ~/.vnc/passwd
    /opt/TurboVNC/bin/vncserver ${DISPLAY} \
      -geometry ${DISPLAY_SIZEW}x${DISPLAY_SIZEH} \
      -depth ${DISPLAY_CDEPTH} \
      -auth ~/.vnc/passwd \
      -x509key /opt/caddy/tls/container.key \
      -x509cert /opt/caddy/tls/container.crt

    /usr/bin/openbox --config-file /var/run/openbox/rc.xml --startup /opt/TurboVNC/bin/xstartup.turbovnc
}

function is_nvidia_capable() {
    if which nvidia-smi > /dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi
}


start 2>&1