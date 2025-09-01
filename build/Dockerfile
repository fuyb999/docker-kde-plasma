# For build automation - Allows building from any ai-dock base image
ARG IMAGE_BASE="ghcr.io/ai-dock/base-image:v2-cuda-12.1.1-cudnn8-runtime-22.04"

FROM ${IMAGE_BASE} as vaapibuilder

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends curl jq pkg-config libffmpeg-nvenc-dev libva-dev libdrm-dev libegl1 libegl-dev python3-pip python3-venv build-essential cmake ninja-build \
    && echo "**** Build NVIDIA VAAPI manually ****" \
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

ARG XPU_TARGET="NVIDIA_GPU"
ARG XORG_ENABLED=false
ARG VIRTUALGL_ENABLED=false
ARG PLASMA_ENABLED=false
ARG PIPEWIRE_ENABLED=false
ARG SELKIES_ENABLED=false
ARG KASMVNC_ENABLED=false
ARG TURBOVNC_ENABLED=false
ARG FIREFOX_ENABLED=false

ENV XPU_TARGET=${XPU_TARGET}
ENV XORG_ENABLED=${XORG_ENABLED}
ENV VIRTUALGL_ENABLED=${VIRTUALGL_ENABLED}
ENV PLASMA_ENABLED=${PLASMA_ENABLED}
ENV PIPEWIRE_ENABLED=${PIPEWIRE_ENABLED}
ENV SELKIES_ENABLED=${SELKIES_ENABLED}
ENV KASMVNC_ENABLED=${KASMVNC_ENABLED}
ENV TURBOVNC_ENABLED=${TURBOVNC_ENABLED}
ENV FIREFOX_ENABLED=${FIREFOX_ENABLED}

ENV SELKIES_VENV=$VENV_DIR/selkies
ENV SELKIES_VENV_PYTHON=$SELKIES_VENV/bin/python
ENV SELKIES_VENV_PIP=$SELKIES_VENV/bin/pip

ENV USER_GROUPS=${USER_GROUPS},input,lpadmin
ENV DISPLAY=:0
ENV VNC_DISPLAY=:1

ENV PIPEWIRE_LATENCY="32/48000"
# https://forum.manjaro.org/t/howto-troubleshoot-crackling-in-pipewire/82442
ENV PULSE_LATENCY_MSEC=60
ENV DISABLE_RTKIT="y"

ENV VGL_DISPLAY=egl

ARG KASMVNC_VERSION=1.3.1
ENV KASMVNC_VERSION=${KASMVNC_VERSION}

ENV PATH=/usr/local/nvidia/bin:/opt/VirtualGL/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}:/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV SDL_JOYSTICK_DEVICE=/dev/input/js0

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV __GL_SYNC_TO_VBLANK=0

ENV TZ=Asia/Shanghai
ENV DISPLAY_SIZEW=1920
ENV DISPLAY_SIZEH=1080
ENV DISPLAY_REFRESH=60
ENV DISPLAY_DPI=96
ENV DISPLAY_CDEPTH=24

ARG SELKIES_VERSION=1.6.1
ENV SELKIES_VERSION=${SELKIES_VERSION}
ENV SELKIES_ENCODER=nvh264enc
ENV SELKIES_ENABLE_RESIZE=false
ENV SELKIES_ENABLE_BASIC_AUTH=false

ENV XDG_RUNTIME_DIR=/tmp/runtime-user
ENV XDG_SESSION_TYPE=x11
ENV FORCE_X11_DUMMY_CONFIG=false

# KDE,xfce
ENV XDG_CURRENT_DESKTOP=xfce
ENV XDG_SESSION_DESKTOP=xfce

# plasma,xfce
ENV DESKTOP_SESSION=xfce
ENV KDE_FULL_SESSION=true
ENV KDE_APPLICATIONS_AS_SCOPE=1
ENV KWIN_COMPOSE=N
ENV KWIN_X11_NO_SYNC_TO_VBLANK=1
ENV SUDO_EDITOR=kate

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

COPY --from=vaapibuilder /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/dri

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
        && ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone \
        && dpkg-reconfigure tzdata \
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

ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN:zh
ENV LC_ALL zh_CN.UTF-8

# Use build scripts to ensure we can build all targets from one Dockerfile in a single layer.
# Don't put anything heavy in here - We can use multi-stage building above if necessary.

# RUN set -eo pipefail && /opt/ai-dock/bin/build/layer0/init.sh | tee /var/log/build.log

# Copy overrides and new files into a final layer for fast rebuilds. Uncomment below
#COPY --chown=0:1111 ./COPY_ROOT_99/ /
#RUN set -eo pipefail && /opt/ai-dock/bin/build/layer99/init.sh | tee -a /var/log/build.log

RUN \
    echo "**** Install core requirements ****" \
        && apt-get update \
        && apt-get install -y --no-install-recommends sudo fakeroot sox file git bc jq acl less tree curl rar unar unrar unzip vim wget xz-utils zip bzip2 gzip htop lsof mlocate net-tools rsync openssh-server pkg-config ca-certificates python3 \
    && \
    echo "**** Install libtcmalloc ****" \
        && apt-get install -y --no-install-recommends libtcmalloc-minimal4 \
        && ln -sf $(ldconfig -p | grep -Po "libtcmalloc_minimal.so.\d" | head -n 1) /lib/x86_64-linux-gnu/libtcmalloc.so \
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

# Install X Server requirements
# apt-get install -y --no-install-recommends alsa-base alsa-utils clinfo cups-browsed cups-bsd cups-common cups-filters cups-pdf dbus-user-session dbus-x11 gstreamer1.0-plugins-bad libgstreamer-plugins-bad1.0-dev im-config lame libavcodec-extra libdatetime-perl libdbus-c++-1-0v5 libegl1 libegl-dev libelf-dev libgles2 libgl1 libglu1 libglvnd0 libopenjp2-7 libopus0 libpulse0 libsm6 libva2 libva-dev libvulkan-dev libxcb1 libxau6 libx11-6 libxext6 libxkbcommon0 libxrandr-dev libxdmcp6 libxv1 libxvmc1 libxtst6 libzita-alsa-pcmi0 libzita-resampler1 mesa-utils mesa-utils-extra mesa-vulkan-drivers meson net-tools ocl-icd-libopencl1 packagekit-tools python3 python3-cups ubuntu-drivers-common vainfo va-driver-all vdpau-driver-all vdpauinfo vulkan-tools whoopsie wmctrl x11-apps x11-utils x11-xkb-utils x11-xserver-utils x264 x265 xauth xbitmaps xclip xcvt cups-bsd xdg-user-dirs xdg-utils xfonts-base xfonts-scalable xinit xkb-data xsel xsettingsd xserver-xorg-input-all xserver-xorg-input-wacom xserver-xorg-video-all xserver-xorg-video-qxl xorg xvfb \
# apt-get install -y --no-install-recommends avahi-utils dbus-x11 dbus-user-session libxcomposite-dev libxcursor1 wmctrl libfuse2 x11-utils x11-xfs-utils x11-xkb-utils x11-xserver-utils x11vnc xauth xbindkeys xclip xcvt xdotool xfishtank xfonts-base xinit xorg xserver-xorg-core xserver-xorg-input-evdev xserver-xorg-input-libinput xserver-xorg-legacy xserver-xorg-video-all xserver-xorg-video-dummy \
# TODO: xauth only for turbovnc and bigger
RUN set -e; \
    [ "$XORG_ENABLED" = "true" ] && { \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install X Server requirements ****" \
        && apt-get install -y --no-install-recommends dbus-x11 dbus-user-session x11-utils avahi-utils xauth \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    ;} || echo "Xorg disabled."

RUN set -e; \
    [ "$XPU_TARGET" = "CPU" ] || [ "$XPU_TARGET" = "NVIDIA_GPU" ] && { \
    echo "**** Install video streaming deps ****" \
        && apt-get update \
        && apt-get install -y --no-install-recommends i965-va-driver-shaders intel-media-va-driver-non-free xserver-xorg-video-intel \
    ;} || echo "XPU_TARGET CPU disabled."

COPY --chown=0:1111 ./COPY_ROOT_0/opt/ai-dock/share/ /opt/ai-dock/share
RUN \
    echo "**** Install NVIDIA VAAPI drivers ****" \
        && apt-get update \
        && apt-get install -y --no-install-recommends vulkan-tools libvulkan1 libglu1-mesa \
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

#    [ "$VIRTUALGL_ENABLED" = "true" ] && { \
RUN \
    echo "**** Install Virtualgl requirements ****" \
        && cd /tmp \
        && export VIRTUALGL_VERSION="3.1.2" \
        && env-store VIRTUALGL_VERSION \
        && wget "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" \
        && apt-get install -y --no-install-recommends ./virtualgl_${VIRTUALGL_VERSION}_amd64.deb \
        && chmod u+s /usr/lib/{libvglfaker,libvglfaker-nodl,libvglfaker-opencl,libdlfaker,libgefaker}.so \
        && cd - \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*
#    ;} || echo "Virtualgl disabled."

RUN set -e; \
    [ "$PLASMA_ENABLED" = "true" ] && { \
    echo "**** Install Plasma kde requirements ****" \
        && apt-get update \
        && apt-get install -y --no-install-recommends kde-plasma-desktop adwaita-icon-theme-full appmenu-gtk3-module ark aspell aspell-en breeze breeze-cursor-theme breeze-gtk-theme breeze-icon-theme debconf-kde-helper desktop-file-utils dolphin dolphin-plugins dbus-x11 fonts-dejavu fonts-freefont-ttf fonts-hack fonts-liberation fonts-noto fonts-noto-cjk fonts-noto-cjk-extra fonts-noto-color-emoji fonts-noto-extra fonts-noto-hinted fonts-noto-mono fonts-noto-unhinted fonts-opensymbol fonts-symbola fonts-ubuntu enchant-2 filelight frameworkintegration gwenview haveged hunspell im-config kate kcalc kcharselect kdeadmin fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-qt5 kde-config-fcitx5 kde-config-gtk-style kde-config-gtk-style-preview kdeconnect kdegraphics-thumbnailers kde-spectacle kdf kdialog kget kimageformat-plugins kinfocenter kio kio-extras kmag kmenuedit kmix kmousetool kmouth ksshaskpass ktimer kwayland-integration kwin-addons kwin-x11 libdbusmenu-glib4 libdbusmenu-gtk3-4 libgail-common libgdk-pixbuf2.0-bin libgtk2.0-bin libgtk-3-bin libkf5baloowidgets-bin libkf5dbusaddons-bin libkf5iconthemes-bin libkf5kdelibs4support5-bin libkf5khtml-bin libkf5parts-plugins libqt5multimedia5-plugins librsvg2-common media-player-info okular okular-extra-backends partitionmanager plasma-browser-integration plasma-calendar-addons plasma-dataengines-addons plasma-discover plasma-integration plasma-runners-addons plasma-widgets-addons policykit-desktop-privileges polkit-kde-agent-1 print-manager qapt-deb-installer qml-module-org-kde-runnermodel qml-module-org-kde-qqc2desktopstyle qml-module-qtgraphicaleffects qml-module-qtquick-xmllistmodel qt5-gtk-platformtheme qt5-image-formats-plugins qt5-style-plugins qtspeech5-flite-plugin qtvirtualkeyboard-plugin software-properties-qt sonnet-plugins sweeper systemsettings ubuntu-drivers-common xdg-desktop-portal-kde xdg-user-dirs pavucontrol-qt \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    ;} || echo "Plasma disabled."

RUN set -e; \
    [ "$PIPEWIRE_ENABLED" = "true" ] && { \
     echo "**** Install Audio and Video requirements ****" \
        curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xFC43B7352BCC0EC8AF2EEB8B25088A0359807596" \
            | gpg --dearmor -o /etc/apt/trusted.gpg.d/pipewire-debian-ubuntu-pipewire-upstream.gpg \
        codename=$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"') \
        echo "deb https://ppa.launchpadcontent.net/pipewire-debian/pipewire-upstream/ubuntu ${codename} main" \
            > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-pipewire-upstream-${codename}.list" \
        echo "deb https://ppa.launchpadcontent.net/pipewire-debian/wireplumber-upstream/ubuntu ${codename} main" \
            > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-wireplumber-upstream-${codename}.list" \
        && apt-get update \
        && apt-get install -y --no-install-recommends pipewire pipewire-alsa pipewire-audio-client-libraries pipewire-jack pipewire-locales pipewire-v4l2 pipewire-libcamera gstreamer1.0-pipewire libpipewire-0.3-modules libpipewire-module-x11-bell libspa-0.2-jack libspa-0.2-modules wireplumber wireplumber-locales gir1.2-wp-0.4 \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    ;} || echo "Pipewire and Wireplumber disabled."

RUN set -e; \
    [ "$SELKIES_ENABLED" = "true" ] && { \
    echo "**** Install Selkies requirements ****" \
        && export PIP_BREAK_SYSTEM_PACKAGES=1 \
        && apt-get update \
        && apt-get install -y --no-install-recommends python3-pip python3-dev python3-gi python3-setuptools python3-wheel python3-venv libaa1 bzip2 libgcrypt20 libcairo-gobject2 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libsoup2.4-1 libsoup-gnome2.4-1 libgirepository-1.0-1 glib-networking libglib2.0-0 libjson-glib-1.0-0 libgudev-1.0-0 alsa-utils jackd2 libjack-jackd2-0 libpulse0 libogg0 libopus0 libvorbis-dev libjpeg-turbo8 libopenjp2-7 libvpx-dev libwebp-dev x264 x265 libdrm2 libegl1 libgl1 libopengl0 libgles1 libgles2 libglvnd0 libglx0 wayland-protocols libwayland-dev libwayland-egl1 wmctrl xsel xdotool x11-utils x11-xserver-utils xserver-xorg-core libx11-xcb1 libxcb-dri3-0 libxkbcommon0 libxdamage1 libxfixes3 libxv1 libxtst6 libxext6 xcvt libopenh264-dev libde265-0 svt-av1 aom-tools \
        && python3 -m venv --system-site-packages "$SELKIES_VENV" \
        && cd /opt \
        && curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/gstreamer-selkies_gpl_v${SELKIES_VERSION}_ubuntu$(grep VERSION_ID= /etc/os-release | cut -d= -f2 | tr -d '\"')_$(dpkg --print-architecture).tar.gz" | tar -xzf - \
        && curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-web_v${SELKIES_VERSION}.tar.gz" | tar -xzf - \
        && cd /tmp \
        && curl -O -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" \
               "$SELKIES_VENV_PIP" install --no-cache-dir --force-reinstall setuptools==61 \
               "$SELKIES_VENV_PIP" install --no-cache-dir --force-reinstall "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" \
               "$SELKIES_VENV_PIP" install --no-cache-dir --force-reinstall websockets==10.4 \
        && curl -o selkies-js-interposer.deb -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-js-interposer_v${SELKIES_VERSION}_ubuntu$(grep VERSION_ID= /etc/os-release | cut -d= -f2 | tr -d '\"')_$(dpkg --print-architecture).deb" \
        && apt-get install -y --no-install-recommends ./selkies-js-interposer.deb \
        && cd - \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    ;} || echo "Selkies disabled."

RUN set -e; \
    [ "$KASMVNC_ENABLED" = "true" ] && { \
    echo "**** Install KasmVNC requirements ****" \
        && cd /tmp \
        && export YQ_VERSION="$(curl -fsSL "https://api.github.com/repos/mikefarah/yq/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" \
        && curl -o yq -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(dpkg --print-architecture)" \
        && install ./yq /usr/local/bin/ \
        && wget https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/kasmvncserver_jammy_${KASMVNC_VERSION}_amd64.deb \
        && apt-get install -y --no-install-recommends ./kasmvncserver_jammy_${KASMVNC_VERSION}_amd64.deb \
        && cd - \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    ;} || echo "KasmVNC disabled."

# TODO: python3 only for turbovnc and bigger
RUN set -e; \
    [ "$TURBOVNC_ENABLED" = "true" ] && { \
    echo "**** Install TurboVNC requirements ****" \
        && cd /tmp \
        && export TURBOVNC_VERSION="3.2" \
        && wget https://github.com/TurboVNC/turbovnc/releases/download/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
        && apt-get install -y --no-install-recommends ./turbovnc_${TURBOVNC_VERSION}_amd64.deb \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    ;} || echo "TurboVNC disabled."

RUN set -e; \
    [ "$FIREFOX_ENABLED" = "true" ] && { \
    echo "**** Install Firefox requirements ****" \
        && mkdir -pm755 /etc/apt/trusted.gpg.d && curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0AB215679C571D1C8325275B9BDB3D89CE49EC21" | gpg --dearmor -o /etc/apt/trusted.gpg.d/mozillateam-ubuntu-ppa.gpg \
        && mkdir -pm755 /etc/apt/sources.list.d && echo "deb https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu $(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"') main" > "/etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').list" \
        && apt-get update \
        && apt-get install -y --no-install-recommends firefox \
        && update-alternatives --set x-www-browser /usr/bin/firefox \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    ;} || echo "Firefox disabled."

# fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-gtk4
RUN apt-get update \
      && apt-get install --no-install-recommends -y xterm openbox \
      && mkdir -p /usr/share/xsessions \
      && touch /usr/share/xsessions/xfce.desktop \
      && echo "Exec=/startapp.sh" > /usr/share/xsessions/xfce.desktop \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*

COPY ttf-wps-fonts /tmp/ttf-wps-fonts
RUN \
    echo "**** Install ttf-wps-fonts ****" \
        && chmod +x /tmp/ttf-wps-fonts/install.sh \
        && /tmp/ttf-wps-fonts/install.sh \
        && rm -rf /tmp/ttf-wps-fonts \
    && \
    echo

# Copy early so we can use scripts in the build - Changes to these files will invalidate the cache and cause a rebuild.
COPY --chown=0:1111 ./COPY_ROOT_0/ /
RUN find /etc/services.d/ -type f \( -name '*.dep' -o -name 'respawn' \) | xargs chmod 666
RUN find /etc/services.d/ -type f -name "respawn" | xargs rm -f

RUN echo "**** Fix permissions ****" \
        && chmod +x /opt/ai-dock/bin/*.sh \
        && fix-permissions.sh -o container \
        && rm -f /etc/ld.so.cache \
        && ldconfig \
    && \
    echo

# Keep init.sh as-is and place additional logic in /opt/ai-dock/bin/preflight.sh
CMD ["init.sh"]
