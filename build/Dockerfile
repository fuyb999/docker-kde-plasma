# For build automation - Allows building from any ai-dock base image
ARG IMAGE_BASE="ghcr.io/ai-dock/base-image:v2-cuda-12.1.1-cudnn8-runtime-22.04"

FROM ${IMAGE_BASE} AS vaapibuilder

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends curl jq pkg-config libffmpeg-nvenc-dev libva-dev libdrm-dev libegl1 libegl-dev python3-pip python3-venv build-essential cmake ninja-build

RUN \
    echo "**** Build NVIDIA VAAPI manually ****" \
        && export NVIDIA_VAAPI_DRIVER_VERSION="$(curl -fsSL "https://api.github.com/repos/elFarto/nvidia-vaapi-driver/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" \
        && curl -fsSL "https://github.com/elFarto/nvidia-vaapi-driver/archive/v${NVIDIA_VAAPI_DRIVER_VERSION}.tar.gz" | tar -xzf - \
        && mv -f nvidia-vaapi-driver* nvidia-vaapi-driver \
        && cd nvidia-vaapi-driver \
        && export VAAPI_VENV="/tmp/vaapi" \
        && python3 -m venv --system-site-packages "$VAAPI_VENV" \
        && $VAAPI_VENV/bin/pip install --no-cache-dir meson \
        && $VAAPI_VENV/bin/meson setup build \
        && $VAAPI_VENV/bin/meson install -C build


FROM ${IMAGE_BASE}

LABEL org.opencontainers.image.source="https://github.com/ai-dock/linux-desktop"
LABEL org.opencontainers.image.description="Docker desktop environment with hardware acceleration for NVIDIA, AMD and Intel GPUs"
LABEL maintainer="Rob Ballantyne <rob@dynamedia.uk>"

ENV USER_GROUPS=${USER_GROUPS},input
ENV DISPLAY=:0
ENV VNC_DISPLAY=:1
ENV VGL_DISPLAY=egl

ENV PATH=/usr/local/nvidia/bin:/opt/VirtualGL/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}:/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV SDL_JOYSTICK_DEVICE=/dev/input/js0

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV __GL_SYNC_TO_VBLANK=0

ENV DISPLAY_SIZEW=1920
ENV DISPLAY_SIZEH=1080
ENV DISPLAY_REFRESH=60
ENV DISPLAY_DPI=96
ENV DISPLAY_CDEPTH=24

ENV XDG_RUNTIME_DIR=/run/user/${USER_ID}
ENV XDG_SESSION_TYPE=x11
ENV FORCE_X11_DUMMY_CONFIG=false

# KDE,xfce
ENV XDG_CURRENT_DESKTOP=xfce
ENV XDG_SESSION_DESKTOP=xfce

# plasma,xfce
ENV DESKTOP_SESSION=xfce

# Set input to fcitx5
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
#ENV XIM fcitx
ENV XMODIFIERS="@im=fcitx"

ENV APPIMAGE_EXTRACT_AND_RUN=1

ARG WINE_BRANCH=staging
ENV WINE_BRANCH=${WINE_BRANCH}

ENV OPT_SYNC=$OPT_SYNC
ENV IMAGE_SLUG="linux-desktop"

ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# Update locale
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install and configure locals ****" \
        && apt-get install -y --no-install-recommends \
            tzdata \
            locales \
            language-pack-zh-hans \
            fonts-wqy-zenhei \
        && echo 'zh_CN.UTF-8 UTF-8' > /etc/locale.gen \
        && locale-gen \
    && \
    echo "**** Configure timezone ****" \
        && ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
        && echo "${TZ}" > /etc/timezone \
        && dpkg-reconfigure tzdata \
    && \
    echo "**** Install core requirements ****" \
        && apt-get update \
        && apt-get install -y --no-install-recommends sudo fakeroot ssl-cert kmod base-files udev sox file git bc jq acl less tree curl rar unar unrar unzip vim wget xz-utils zip bzip2 gzip htop lsof mlocate net-tools rsync openssh-server pkg-config ca-certificates pciutils \
    && \
    echo "**** Install libtcmalloc ****" \
        && apt-get install -y --no-install-recommends libtcmalloc-minimal4 \
        && ln -sf $(ldconfig -p | grep -Po "libtcmalloc_minimal.so.\d" | head -n 1) /lib/x86_64-linux-gnu/libtcmalloc.so \
    && \
#    echo "**** Install X Server requirements ****" \
#        && apt-get install -y --no-install-recommends dbus-x11 dbus-user-session x11-utils x11-xkb-utils xkb-data avahi-utils libxfont2 libpixman-1-0 xauth \
#    && \
#        && apt-get install -y --no-install-recommends openbox \
    echo "**** Install Openbox requirements ****" \
        && mkdir -p /usr/share/xsessions \
        && touch /usr/share/xsessions/xfce.desktop \
        && echo "Exec=/usr/bin/openbox --config-file /etc/openbox/rc.xml" > /usr/share/xsessions/xfce.desktop \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

COPY --from=vaapibuilder /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/dri
COPY --chown=0:1111 ./COPY_ROOT_0/opt/ai-dock/share/ /opt/ai-dock/share
RUN \
    echo "**** Install NVIDIA VAAPI drivers ****" \
        && apt-get update \
        && apt-get install -y --no-install-recommends vulkan-tools libvulkan1 libglu1-mesa libegl1 \
        && printf "/usr/local/nvidia/lib\n" >> /etc/ld.so.conf.d/nvidia.conf \
        && printf "/usr/local/nvidia/lib64\n" >> /etc/ld.so.conf.d/nvidia.conf \
        && echo "**** Configure OpenCL manually ****" \
            && mkdir -pm755 /etc/OpenCL/vendors \
            && printf "libnvidia-opencl.so.1\n" > /etc/OpenCL/vendors/nvidia.icd \
        && echo "**** Configure Vulkan manually ****" \
            && export VULKAN_API_VERSION=$(dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)') \
            && mkdir -pm755 /etc/vulkan/icd.d/ \
            && cp /opt/ai-dock/share/vulkan/icd.d/nvidia_icd.json /etc/vulkan/icd.d/ \
            && sed -i "s/\$VULKAN_API_VERSION/$VULKAN_API_VERSION/g" /etc/vulkan/icd.d/nvidia_icd.json \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*

#RUN \
#    echo "**** Install Virtualgl requirements ****" \
#        && cd /tmp \
#        && export VIRTUALGL_VERSION="3.1.2" \
#        && env-store VIRTUALGL_VERSION \
#        && wget "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" \
#        && apt-get install -y --no-install-recommends ./virtualgl_${VIRTUALGL_VERSION}_amd64.deb \
#        && chmod u+s /usr/lib/{libvglfaker,libvglfaker-nodl,libvglfaker-opencl,libdlfaker,libgefaker}.so \
#        && cd - \
#    && \
#    echo "**** Section cleanup ****" \
#        && apt-get clean autoclean -y \
#        && apt-get autoremove -y \
#        && rm -rf \
#            /var/lib/apt/lists/* \
#            /var/tmp/* \
#            /tmp/*
#
## TODO: python3 only for turbovnc and bigger
#RUN \
#    echo "**** Install TurboVNC requirements ****" \
#        && cd /tmp \
#        && export TURBOVNC_VERSION="3.2" \
#        && wget https://github.com/TurboVNC/turbovnc/releases/download/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
#        && apt-get install -y --no-install-recommends ./turbovnc_${TURBOVNC_VERSION}_amd64.deb \
#    && \
#    echo "**** Section cleanup ****" \
#        && apt-get clean autoclean -y \
#        && apt-get autoremove -y \
#        && rm -rf \
#            /var/lib/apt/lists/* \
#            /var/tmp/* \
#            /tmp/*

RUN apt-get update \
      && apt-get install --no-install-recommends -y pciutils \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*

#COPY ttf-wps-fonts /tmp/ttf-wps-fonts
#RUN \
#    echo "**** Install ttf-wps-fonts ****" \
#        && chmod +x /tmp/ttf-wps-fonts/install.sh \
#        && /tmp/ttf-wps-fonts/install.sh \
#        && rm -rf /tmp/ttf-wps-fonts \
#    && \
#    echo

# Copy early so we can use scripts in the build - Changes to these files will invalidate the cache and cause a rebuild.
COPY --chown=0:1111 ./COPY_ROOT_0/ /

RUN find /etc/services.d/ -type f \( -name '*.dep' -o -name 'params' \) | xargs chmod 666 && \
    find /etc/services.d/ -type f -name "respawn" | xargs rm -f

RUN echo "**** Fix permissions ****" \
        && chmod +x /opt/ai-dock/bin/*.sh \
        && fix-permissions.sh -o container \
        && rm -f /etc/ld.so.cache \
        && ldconfig \
    && \
    echo