#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh

# 彻底禁用交互式配置
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export UCF_FORCE_CONFFOLD=1

export XDG_SOFTWARE_HOME=${XDG_SOFTWARE_HOME:-/opt/apps}
export XDG_ADDONS_HOME=${XDG_ADDONS_HOME:-/opt/addons}
export SOFTWARE_ADDONS_DIR=${XDG_ADDONS_HOME}/softwares
export CRACK_ADDONS_DIR=${XDG_ADDONS_HOME}/crack
export JAVA_HOME=${XDG_SOFTWARE_HOME}/jdk-${JDK_VERSION}
export MAVEN_HOME=${XDG_SOFTWARE_HOME}/apache-maven-${MAVEN_VERSION}
export DBEAVER_HOME=${XDG_SOFTWARE_HOME}/dbeaver-${DBEAVER_VERSION}
export NODE_HOME=${XDG_SOFTWARE_HOME}/node-v${NODE_VERSION}
export FIREFOX_HOME=${XDG_SOFTWARE_HOME}/firefox-${FIREFOX_VERSION}
export OSS_BROWSER_HOME=${XDG_SOFTWARE_HOME}/oss-browser-${OSS_BROWSER_VERSION}
export WIND_TERM_HOME=${XDG_SOFTWARE_HOME}/WindTerm-${WIND_TERM_VERSION}
export ANACONDA_HOME=${XDG_SOFTWARE_HOME}/anaconda3-${CONDA_VERSION}
export IDEA_HOME=${XDG_SOFTWARE_HOME}/ideaIU-${IDEA_VERSION}

export LD_LIBRARY_PATH="${WIND_TERM_HOME}/lib:${LD_LIBRARY_PATH:-:/usr/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:/usr/local/nvidia/lib:/usr/local/nvidia/lib64}"
export PATH=${PATH}:${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${DBEAVER_HOME}:${NODE_HOME}/bin:${FIREFOX_HOME}:${OSS_BROWSER_HOME}:${WIND_TERM_HOME}:${ANACONDA_HOME}/bin:${IDEA_HOME}/bin

export JREBEL_SERVER_HOME=${XDG_SOFTWARE_HOME}/jrebel-license-server
export JETBRA_ALL_PATH=${XDG_SOFTWARE_HOME}/jetbra-all

env-store XDG_SOFTWARE_HOME
env-store XDG_ADDONS_HOME
env-store SOFTWARE_ADDONS_DIR
env-store JAVA_HOME
env-store MAVEN_HOME
env-store DBEAVER_HOME
env-store NODE_HOME
env-store FIREFOX_HOME
env-store ANACONDA_HOME
env-store IDEA_HOME
env-store JREBEL_SERVER_HOME
env-store LD_LIBRARY_PATH
env-store PATH

if [[ ${SERVERLESS,,} = "true" ]]; then
    printf "Refusing to start softwares in serverless mode\n"
    exit 0
fi

[ -d ${XDG_SOFTWARE_HOME} ] || sudo chown ${USER_ID}:${GROUP_ID} ${XDG_SOFTWARE_HOME}

install_x11(){

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/apt-offline-x11-mirror.tar.xz" ] || [ -z "${OFFLINE_CORE_PACKEGES}" ]; then
    return 0
  fi

  if command -v fcitx5 > /dev/null; then
    return 0
  fi

  echo "try install x11 requirements"

  sudo tar -Jxf ${SOFTWARE_ADDONS_DIR}/apt-offline-x11-mirror.tar.xz -C /
  sudo mv /etc/apt/sources.list.d/local.list /etc/apt/sources.list

  # 预先设置所有键盘配置
  sudo debconf-set-selections <<'EOF'
  keyboard-configuration keyboard-configuration/layoutcode string us
  keyboard-configuration keyboard-configuration/variantcode string
  keyboard-configuration keyboard-configuration/modelcode string pc105
  keyboard-configuration keyboard-configuration/unsupported_layout boolean true
  keyboard-configuration keyboard-configuration/unsupported_config_options boolean true
  keyboard-configuration keyboard-configuration/store_defaults_in_debconf_db boolean true
  keyboard-configuration keyboard-configuration/altgr select The default for the keyboard layout
  keyboard-configuration keyboard-configuration/compose select No compose key
  keyboard-configuration keyboard-configuration/ctrl_alt_bksp boolean false
  keyboard-configuration keyboard-configuration/variant select English
  keyboard-configuration keyboard-configuration/switch select No temporary switch
  keyboard-configuration keyboard-configuration/xkb-keymap select us
EOF

  sudo apt-get update
  sudo apt-get install -y -q --no-install-recommends \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold" \
      ${OFFLINE_CORE_PACKEGES}

  if [ -f "${SOFTWARE_ADDONS_DIR}/virtualgl_${VIRTUALLGL_VERSION}_amd64.deb" ]; then
    sudo dpkg -i ${SOFTWARE_ADDONS_DIR}/virtualgl_${VIRTUALLGL_VERSION}_amd64.deb
    sudo chmod u+s /usr/lib/{libvglfaker,libvglfaker-nodl,libvglfaker-opencl,libdlfaker,libgefaker}.so
  fi

  if [ -f "${SOFTWARE_ADDONS_DIR}/turbovnc_${TURBOVNC_VERSION}_amd64.deb" ]; then
    sudo dpkg -i ${SOFTWARE_ADDONS_DIR}/turbovnc_${TURBOVNC_VERSION}_amd64.deb
  fi

}

install_jdk(){

  if [ ${ENABLE_JDK} -eq 0 ] || [ -n "$(which java)" ]; then
   return 0
  fi

  echo "try install jdk-${JDK_VERSION}"
  
  if [ ! -f "${SOFTWARE_ADDONS_DIR}/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz" ]; then
    wget https://download.oracle.com/java/17/archive/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz -O ${SOFTWARE_ADDONS_DIR}/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz
  fi

  if [ ! -d "${JAVA_HOME}" ]; then
    mkdir -p ${JAVA_HOME}
  fi

  tar --strip-components=1 -zxf ${SOFTWARE_ADDONS_DIR}/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz -C ${JAVA_HOME}

  return 0
}

install_maven(){
  if [ ${ENABLE_MAVEN} -eq 0 ] || [ -n "$(which mvn)" ]; then
    return 0
  fi

  echo "try install maven-${MAVEN_VERSION}"

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/apache-maven-${MAVEN_VERSION}-bin.tar.gz" ]; then
    wget "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -O "${SOFTWARE_ADDONS_DIR}/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
  fi

  if [ ! -d "${MAVEN_HOME}" ]; then
    mkdir -p "${MAVEN_HOME}"
  fi

  tar --strip-components=1 -zxf "${SOFTWARE_ADDONS_DIR}/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -C "${MAVEN_HOME}"

  return 0
}

install_dbeaver(){

  if [ ${ENABLE_DBEAVER} -eq 0 ] || [ -n "$(which dbeaver)" ]; then
    return 0
  fi

  echo "try install dbeaver-${DBEAVER_VERSION}"

  DBEAVER_PRODUCT=${DBEAVER_VERSION:0:2}
  if [ ! -f "${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz" ]; then
    # ${DBEAVER_VERSION:3} -> ce_24.1.2 -> 24.1.2
    if [ "${DBEAVER_PRODUCT}" = "ue" ]; then
      wget https://dbeaver.com/downloads-ultimate/${DBEAVER_VERSION:3}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz -O ${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz
    fi
    if [ "${DBEAVER_PRODUCT}" = "ee" ]; then
      wget https://dbeaver.com/files/${DBEAVER_VERSION:3}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz -O ${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz
    fi
  fi

  if [ ! -d "${DBEAVER_HOME}" ]; then
    mkdir -p ${DBEAVER_HOME}
  fi

  tar --strip-components=1 -zxf ${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz -C ${DBEAVER_HOME}

  # https://github.com/wgzhao/dbeaver-agent
  if [ -f "${CRACK_ADDONS_DIR}/dbeaver/dbeaver-agent-1.0.jar" ] && [ ! -f "${DBEAVER_HOME}/dbeaver-agent-1.0.jar" ]; then
    sudo cp ${CRACK_ADDONS_DIR}/dbeaver/dbeaver-agent-1.0.jar ${DBEAVER_HOME}/dbeaver-agent.jar
  fi

  DBEAVER_CONFIG=${DBEAVER_HOME}/dbeaver.ini
  if [ -z "$(grep dbeaver-agent $DBEAVER_CONFIG)" ]; then
    sudo sed -i -e "/-vmargs/a\-javaagent:${DBEAVER_HOME}/dbeaver-agent.jar" ${DBEAVER_CONFIG}
  fi

  sudo rm -rf ${DBEAVER_HOME}/jre && sudo ln -s ${JAVA_HOME} ${DBEAVER_HOME}/jre
  ${JAVA_HOME}/bin/java -cp ${CRACK_ADDONS_DIR}/dbeaver/libs/\*:${DBEAVER_HOME}/dbeaver-agent.jar \
     dev.misakacloud.dbee.License \
     --product=dbeaver \
     --type=${DBEAVER_PRODUCT} \
     --version=24

  return 0
}

install_node(){

  if [ ${ENABLE_NODE} -eq 0 ] || [ -n "$(which node)" ]; then
    return 0
  fi

  echo "try install node-${NODE_VERSION}"

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz" ]; then
    # ${NODE_VERSION%%.*} -> 16.19.1 -> 16
#    wget https://registry.npmmirror.com/-/binary/node/latest-v${NODE_VERSION%%.*}.x/node-v${NODE_VERSION}-linux-x64.tar.gz -O ${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz
    wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz -O ${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz
  fi

  if [ ! -d "${NODE_HOME}" ]; then
    mkdir -p ${NODE_HOME}
  fi

  tar --strip-components=1 -zxf "${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz" -C "${NODE_HOME}"

  return 0
}

install_firefox(){

  if [ ${ENABLE_FIREFOX} -eq 0 ] || [ -n "$(which firefox)" ]; then
    return 0
  fi

  echo "try install firefox-${FIREFOX_VERSION}"

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/firefox-${FIREFOX_VERSION}.tar.bz2" ]; then
    wget https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/zh-CN/firefox-${FIREFOX_VERSION}.tar.bz2 -O ${SOFTWARE_ADDONS_DIR}/firefox-${FIREFOX_VERSION}.tar.bz2
  fi

  if [ ! -d "${FIREFOX_HOME}" ]; then
    mkdir -p ${FIREFOX_HOME}
  fi

  tar --strip-components=1 -jxf ${SOFTWARE_ADDONS_DIR}/firefox-${FIREFOX_VERSION}.tar.bz2 -C ${FIREFOX_HOME}

  return 0
}

install_google_chrome(){

  if [ ${ENABLE_CHROME} -eq 0 ] || [ -n "$(which google-chrome)" ]; then
    return 0
  fi

  echo "try install google-chrome-${CHROME_VERSION}"

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/google-chrome-stable_${CHROME_VERSION}_amd64.deb" ]; then
    wget https://repo.debiancn.org/debiancn/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}_amd64.deb -O ${SOFTWARE_ADDONS_DIR}/google-chrome-stable_${CHROME_VERSION}_amd64.deb
  fi

  sudo dpkg -i ${SOFTWARE_ADDONS_DIR}/google-chrome-stable_${CHROME_VERSION}_amd64.deb

  return 0
}

install_oss_browser(){

  if [ ${ENABLE_OSS_BROWSER} -eq 0 ] || [ -n "$(which oss-browser)" ]; then
    return 0
  fi

  echo "try install oss-browser-${OSS_BROWSER_VERSION}"

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/oss-browser-${OSS_BROWSER_VERSION}-linux-x64.zip" ]; then
    wget https://github.com/aliyun/oss-browser/releases/download/v${OSS_BROWSER_VERSION}/oss-browser-linux-x64.zip -O ${SOFTWARE_ADDONS_DIR}/oss-browser-${OSS_BROWSER_VERSION}-linux-x64.zip
  fi

  if [ ! -d "${OSS_BROWSER_HOME}" ]; then
    mkdir -p ${OSS_BROWSER_HOME}
  fi

  unzip -oq ${SOFTWARE_ADDONS_DIR}/oss-browser-${OSS_BROWSER_VERSION}-linux-x64.zip -d ${OSS_BROWSER_HOME}
  find "${OSS_BROWSER_HOME}" -mindepth 1 -maxdepth 1 -type d -exec bash -c 'mv "$1"/* "$OSS_BROWSER_HOME"/ 2>/dev/null && rmdir "$1"' _ {} \;

  return 0
}

install_wind_term(){

  if [ ${ENABLE_WIND_TERM} -eq 0 ] || [ -n "$(which WindTerm)" ]; then
    return 0
  fi

  echo "try install WindTerm-${WIND_TERM_VERSION}"

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/WindTerm_${WIND_TERM_VERSION}_Linux_Portable_x86_64.zip" ]; then
    wget https://github.com/kingToolbox/WindTerm/releases/download/${WIND_TERM_VERSION}/WindTerm_${WIND_TERM_VERSION}_Linux_Portable_x86_64.zip -O ${SOFTWARE_ADDONS_DIR}/WindTerm_${WIND_TERM_VERSION}_Linux_Portable_x86_64.zip
  fi

  if [ ! -d "${WIND_TERM_HOME}" ]; then
    mkdir -p ${WIND_TERM_HOME}
  fi

  unzip -oq ${SOFTWARE_ADDONS_DIR}/WindTerm_${WIND_TERM_VERSION}_Linux_Portable_x86_64.zip -d ${WIND_TERM_HOME}
  find "${WIND_TERM_HOME}" -mindepth 1 -maxdepth 1 -type d -exec bash -c 'mv "$1"/* "$WIND_TERM_HOME"/ 2>/dev/null && rmdir "$1"' _ {} \;

  chmod +x ${WIND_TERM_HOME}/WindTerm

  return 0
}

install_anaconda3(){

  if [ ${ENABLE_CONDA} -eq 0 ] || [ -n "$(which conda)" ]; then
    return 0
  fi

  echo "try install anaconda3-${CONDA_VERSION}"

  tee $HOME/.condarc << EOF
  envs_dirs:
    - ${ANACONDA_HOME}/envs
  pkgs_dirs:
    - ${ANACONDA_HOME}/pkgs
  auto_activate_base: true
  show_channel_urls: true
  channels:
    - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
    - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
    - defaults
EOF

  chmod 644 ${HOME}/.condarc

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh" ]; then
    #apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6
    wget -nc https://repo.anaconda.com/archive/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh -O ${SOFTWARE_ADDONS_DIR}/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh
  fi

  if [ ! -d "$ANACONDA_HOME" ]; then
    bash ${SOFTWARE_ADDONS_DIR}/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh -b -p ${ANACONDA_HOME} -f
  fi

  # 调用 conda init 初始化conda 在 $HOME/.bashrc 添加初始化脚本 自动激活conda base
  chmod -R +x ${ANACONDA_HOME} && ${ANACONDA_HOME}/bin/conda init bash

  return 0
}

install_idea(){

  if [ -n "$(which idea)" ]; then
    return 0
  fi

  echo "try install ideaIU-${IDEA_VERSION}"

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz" ]; then
    wget "https://download.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz" -O "${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz"
  fi

  if [ ! -d "${IDEA_HOME}" ]; then
    mkdir -p "${IDEA_HOME}"
  fi

  # Install jetbra
  if [ -f "${CRACK_ADDONS_DIR}/jetbra-all.zip" ] && [ ! -d ${JETBRA_ALL_PATH} ] ; then
    unzip -oq ${CRACK_ADDONS_DIR}/jetbra-all.zip -d ${JETBRA_ALL_PATH}
    find "${JETBRA_ALL_PATH}" -mindepth 1 -maxdepth 1 -type d -exec bash -c 'mv "$1"/* "$JETBRA_ALL_PATH"/ 2>/dev/null && rmdir "$1"' _ {} \;
  fi

  tar --strip-components=1 -xzf ${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz -C ${IDEA_HOME} && \
    echo "-javaagent:${JETBRA_ALL_PATH}/jetbra-agent.jar=jetbrains" >> ${IDEA_HOME}/bin/idea64.vmoptions && \
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" >> ${IDEA_HOME}/bin/idea64.vmoptions && \
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" >> ${IDEA_HOME}/bin/idea64.vmoptions

  if [ ! -d "${JREBEL_SERVER_HOME}" ]; then
    mkdir -p "${JREBEL_SERVER_HOME}"
  fi

  # Install jrebel-license-server
  if [ -f "${CRACK_ADDONS_DIR}/jrebel/jrebel-license-server-0.0.1.jar" ] && [ ! -f "${JREBEL_SERVER_HOME}/jrebel-license-server.jar" ] ; then
    cp "${CRACK_ADDONS_DIR}/jrebel/jrebel-license-server-*.jar" "${JREBEL_SERVER_HOME}/jrebel-license-server.jar"
  fi

  return 0
}

install_nvidia_driver(){

  if ! command -v nvidia-smi > /dev/null; then
    return 0
  fi

  if command -v nvidia-xconfig > /dev/null; then
    return 0
  fi

  echo "try install Nvidia driver-${IDEA_VERSION}"

  export DRIVER_ARCH="$(dpkg --print-architecture | sed -e 's/arm64/aarch64/'  -e 's/i.*86/x86/' -e 's/amd64/x86_64/' -e 's/unknown/x86_64/')"
  export DRIVER_VERSION="$(head -n1 </proc/driver/nvidia/version | awk '{print $8}')"

  if [ ! -f ${SOFTWARE_ADDONS_DIR}/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run ]; then
    # Download the correct nvidia driver (check multiple locations)
    wget "https://international.download.nvidia.com/XFree86/Linux-${DRIVER_ARCH}/${DRIVER_VERSION}/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run" -O ${SOFTWARE_ADDONS_DIR}/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run || \
    wget "https://international.download.nvidia.com/tesla/${DRIVER_VERSION}/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run" -O ${SOFTWARE_ADDONS_DIR}/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run || { echo "Failed NVIDIA GPU driver download."; }
  fi

  if [ ! -f ${SOFTWARE_ADDONS_DIR}/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run ]; then
    return 0
  fi

  # Extract installer before installing
  sudo bash "${SOFTWARE_ADDONS_DIR}/NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}.run" -x
  cd "NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}"
  # Run installation without the kernel modules and host components
  sudo ./nvidia-installer \
     --silent \
     --no-kernel-module \
     --install-compat32-libs \
     --no-nouveau-check \
     --no-nvidia-modprobe \
     --no-rpms \
     --no-backup \
     --no-check-for-alternate-installs || true
  cd - > /dev/null 2>&1
  sudo rm -rf "NVIDIA-Linux-${DRIVER_ARCH}-${DRIVER_VERSION}"

  return 0
}

install_wps(){

  if [ ${ENABLE_WPS} -eq 0 ] || [ -n "$(which wps)" ]; then
    return 0
  fi

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/wps-office_${WPS_VERSION}_amd64.deb" ]; then
    return 0
  fi

  sudo dpkg -i "${SOFTWARE_ADDONS_DIR}/wps-office_${WPS_VERSION}_amd64.deb"

}

install_podman(){

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/podman-linux-amd64.tar.gz" ]; then
    return 0
  fi

  sudo tar --strip-components=1 -zxf "${SOFTWARE_ADDONS_DIR}/podman-linux-amd64.tar.gz" -C "/"

  [ -f "${SOFTWARE_ADDONS_DIR}/podman-compose" ] && sudo cp "${SOFTWARE_ADDONS_DIR}/podman-compose" /usr/local/bin

  # 配置用户命名空间
  echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a /etc/sysctl.conf
  echo 'user.max_user_namespaces=28633' | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p

  # 配置用户映射
  sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER

  # 重新加载用户组信息
  newgrp "$(id -gn)"

}


install_x11
install_jdk
install_maven
install_node
install_firefox
install_oss_browser
install_google_chrome
install_wind_term
install_dbeaver
install_anaconda3
install_idea
install_nvidia_driver
install_wps
install_podman

# vim:ft=sh:ts=4:sw=4:et:sts=4