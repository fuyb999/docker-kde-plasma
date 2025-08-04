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

# If /dev/dri is not available in te container we will have no HW accel
function start_proxy() {
    echo "proxy" > /tmp/.X-mode
#    /usr/bin/Xvfb "${DISPLAY}" -screen 0 "8192x4096x${DISPLAY_CDEPTH}" -dpi "${DISPLAY_DPI}" +extension "COMPOSITE" +extension "DAMAGE" +extension "GLX" +extension "RANDR" +extension "RENDER" +extension "MIT-SHM" +extension "XFIXES" +extension "XTEST" +iglx +render -nolisten "tcp" -ac -noreset -shmem

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

function is_nvidia_capable() {
    if which nvidia-smi > /dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi
}


start 2>&1