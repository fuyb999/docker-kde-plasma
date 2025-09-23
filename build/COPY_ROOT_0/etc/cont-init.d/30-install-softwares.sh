#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh

export XDG_SOFTWARE_HOME=/opt/apps
export ADDONS_DIR=/opt/addons
export SOFTWARE_ADDONS_DIR=${ADDONS_DIR}/softwares
export CRACK_ADDONS_DIR=${ADDONS_DIR}/crack
export JAVA_HOME=${XDG_SOFTWARE_HOME}/jdk-${JDK_VERSION}
export DBEAVER_HOME=${XDG_SOFTWARE_HOME}/dbeaver-${DBEAVER_VERSION}
export NODE_HOME=${XDG_SOFTWARE_HOME}/node-v${NODE_VERSION}
export FIREFOX_HOME=${XDG_SOFTWARE_HOME}/firefox-${OSS_BROWSER_VERSION}
export OSS_BROWSER_HOME=${XDG_SOFTWARE_HOME}/oss-browser-${FIREFOX_VERSION}
export WIND_TERM_HOME=${XDG_SOFTWARE_HOME}/WindTerm-${WIND_TERM_VERSION}
export ANACONDA_HOME=${XDG_SOFTWARE_HOME}/anaconda3-${CONDA_VERSION}
export IDEA_HOME=${XDG_SOFTWARE_HOME}/ideaIU-${IDEA_VERSION}
export PATH=${PATH}:${JAVA_HOME}/bin:${DBEAVER_HOME}:${NODE_HOME}/bin:${FIREFOX_HOME}:${OSS_BROWSER_HOME}:${WIND_TERM_HOME}:${ANACONDA_HOME}/bin:${IDEA_HOME}/bin

env-store XDG_SOFTWARE_HOME
env-store SOFTWARE_ADDONS_DIR
env-store ADDONS_DIR
env-store JAVA_HOME
env-store DBEAVER_HOME
env-store NODE_HOME
env-store FIREFOX_HOME
env-store ANACONDA_HOME
env-store IDEA_HOME
env-store PATH

install_jdk(){

  if [ ${ENABLE_JDK} -eq 0 ] || [ -n "$(which java)" ]; then
   return 1
  fi

  echo "try install jdk-${JDK_VERSION}"

  # 在 ENV 中定义的PATH 在此不生效
  if [ ! -f $HOME/.bashrc ] || [ -z "$(cat $HOME/.bashrc | grep 'JAVA_HOME')" ]; then
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> $HOME/.bashrc
  fi
  
  if [ ! -f "${SOFTWARE_ADDONS_DIR}/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz" ]; then
    wget https://download.oracle.com/java/17/archive/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz -O ${SOFTWARE_ADDONS_DIR}/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz
  fi

  if [ ! -d "${JAVA_HOME}" ]; then
    mkdir -p ${JAVA_HOME}
  fi

  tar --strip-components=1 -zxf ${SOFTWARE_ADDONS_DIR}/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz -C ${JAVA_HOME}

  return 0
}

install_dbeaver(){

  if [ ${ENABLE_DBEAVER} -eq 0 ] || [ -n "$(which dbeaver)" ]; then
    return 1
  fi

  echo "try install dbeaver-${DBEAVER_VERSION}"

  DBEAVER_PRODUCT=${DBEAVER_VERSION:0:2}
  if [ ! -f "${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz" ]; then
    # ${DBEAVER_VERSION:3} -> ce_24.1.2 -> 24.1.2
    if [ "${DBEAVER_PRODUCT}" = "ue"]; then
      wget https://dbeaver.com/downloads-ultimate/${DBEAVER_VERSION:3}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz -O ${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz
    fi
    if [ "${DBEAVER_PRODUCT}" = "ee"]; then
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
    return 1
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

  tar --strip-components=1 -zxf ${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz -C ${NODE_HOME}

  return 0
}

install_firefox(){

  if [ ${ENABLE_FIREFOX} -eq 0 ] || [ -n "$(which firefox)" ]; then
    return 1
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

install_oss_browser(){

  if [ ${ENABLE_OSS_BROWSER} -eq 0 ] || [ -n "$(which oss-browser)" ]; then
    return 1
  fi

  echo "try install oss-browser-${OSS_BROWSER_VERSION}"

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/oss-browser-${OSS_BROWSER_VERSION}-linux-x64.zip" ]; then
    wget https://github.com/aliyun/oss-browser/releases/download/v${OSS_BROWSER_VERSION}/oss-browser-linux-x64.zip -O ${SOFTWARE_ADDONS_DIR}/oss-browser-${OSS_BROWSER_VERSION}-linux-x64.zip
  fi

  if [ ! -d "${OSS_BROWSER_HOME}" ]; then
    mkdir -p ${OSS_BROWSER_HOME}
  fi

  unzip -oq ${SOFTWARE_ADDONS_DIR}/oss-browser-${OSS_BROWSER_VERSION}-linux-x64.zip -d ${OSS_BROWSER_HOME}

  return 0
}

install_wind_term(){

  if [ ${ENABLE_WIND_TERM} -eq 0 ] || [ -n "$(which WindTerm)" ]; then
    return 1
  fi

  echo "try install WindTerm-${WIND_TERM_VERSION}"

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/WindTerm_${WIND_TERM_VERSION}_Linux_Portable_x86_64.zip" ]; then
    wget https://github.com/kingToolbox/WindTerm/releases/download/${WIND_TERM_VERSION}/WindTerm_${WIND_TERM_VERSION}_Linux_Portable_x86_64.zip -O ${SOFTWARE_ADDONS_DIR}/WindTerm_${WIND_TERM_VERSION}_Linux_Portable_x86_64.zip
  fi

  if [ ! -d "${WIND_TERM_HOME}" ]; then
    mkdir -p ${WIND_TERM_HOME}
  fi

  unzip -oq ${SOFTWARE_ADDONS_DIR}/WindTerm_${WIND_TERM_VERSION}_Linux_Portable_x86_64.zip -d ${WIND_TERM_HOME}

  return 0
}

install_anaconda3(){

  if [ ${ENABLE_CONDA} -eq 0 ] ; then
    return 1
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

  if [ -n "$(which ${IDEA_HOME}/bin/idea.sh)" ]; then
    return 1
  fi

  echo "try install ideaIU-${IDEA_VERSION}"

  # IDEA_BIN_ROOT_NAME="$(tar -tf /ideaIU-${IDEA_VERSION}.tar.gz | awk -F "/" '{print $1}' | sed -n '1p')"
  if [ ! -f "${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz" ]; then
    wget https://download.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz -O ${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz
  fi

  if [ ! -d "${IDEA_HOME}" ]; then
    mkdir -p ${IDEA_HOME}
  fi

  JREBEL_SERVER_HOME=${XDG_SOFTWARE_HOME}/jrebel-license-server
  JETBRA_ALL_PATH=${XDG_SOFTWARE_HOME}/jetbra-all

  # Install jetbra
  if [ -f "${CRACK_ADDONS_DIR}/jetbra-all.zip" ] && [ ! -d ${JETBRA_ALL_PATH} ] ; then
    unzip -oq ${CRACK_ADDONS_DIR}/jetbra-all.zip -d ${JETBRA_ALL_PATH}
  fi

  tar -xzf ${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz --strip-components=1 -C ${IDEA_HOME} && \
    echo "-javaagent:${JETBRA_ALL_PATH}/jetbra-agent.jar=jetbrains" >> ${IDEA_HOME}/bin/idea64.vmoptions && \
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" >> ${IDEA_HOME}/bin/idea64.vmoptions && \
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" >> ${IDEA_HOME}/bin/idea64.vmoptions

  if [ ! -d "${JREBEL_SERVER_HOME}" ]; then
    mkdir -p ${JREBEL_SERVER_HOME}
  fi

  # Install jrebel-license-server
  if [ -f "${CRACK_ADDONS_DIR}/jrebel/jrebel-license-server-0.0.1.jar" ] && [ ! -f ${JREBEL_SERVER_HOME}/jrebel-license-server.jar ] ; then
    cp ${CRACK_ADDONS_DIR}/jrebel/jrebel-license-server-*.jar ${JREBEL_SERVER_HOME}/jrebel-license-server.jar
  fi

  return 0
}

install_jdk
install_node
install_firefox
install_oss_browser
install_wind_term
install_dbeaver
install_anaconda3
install_idea

# vim:ft=sh:ts=4:sw=4:et:sts=4