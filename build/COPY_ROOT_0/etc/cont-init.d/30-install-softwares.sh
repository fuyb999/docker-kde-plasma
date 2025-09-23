#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh

export XDG_SOFTWARE_HOME=/opt/apps
export ADDONS_DIR=${HOME}/addons
export SOFTWARE_ADDONS_DIR=${ADDONS_DIR}/softwares
export CRACK_ADDONS_DIR=${ADDONS_DIR}/crack
export JAVA_HOME=${XDG_SOFTWARE_HOME}/jdk-${JDK_VERSION}
export DBEAVER_HOME=${XDG_SOFTWARE_HOME}/dbeaver-${DBEAVER_VERSION}
export NODE_HOME=${XDG_SOFTWARE_HOME}/node-v${NODE_VERSION}
export FIREFOX_HOME=${XDG_SOFTWARE_HOME}/firefox-${FIREFOX_VERSION}
export ANACONDA_HOME=${XDG_SOFTWARE_HOME}/anaconda3-${CONDA_VERSION}
export IDEA_HOME=${XDG_SOFTWARE_HOME}/ideaIU-${IDEA_VERSION}
export PATH=${PATH}:${JAVA_HOME}/bin:${DBEAVER_HOME}/bin:${NODE_HOME}/bin:${FIREFOX_HOME}/bin:${ANACONDA_HOME}/bin

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

  if [ ${ENABLE_JDK} -eq 0 ]; then
   return 1
  fi
  
  # 在 ENV 中定义的PATH 在此不生效
  if [ ! -f $HOME/.bashrc ] || [ -z "$(cat $HOME/.bashrc | grep 'JAVA_HOME')" ]; then
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> $HOME/.bashrc
  fi
  
  if [ -n "$(which java)" ]; then
    return 1
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

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz" ]; then
    # ${DBEAVER_VERSION:3} -> ce_24.1.2 -> 24.1.2
   # wget https://dbeaver.com/downloads-ultimate/${DBEAVER_VERSION:3}/dbeaver-${DBEAVER_VERSION}_amd64.deb -O ${ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}_amd64.deb
   wget https://dbeaver.com/files/${DBEAVER_VERSION:3}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz -O ${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz
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
     --type=ee \
     --version=24

  return 0
}

install_node(){

  if [ ${ENABLE_NODE} -eq 0 ] || [ -n "$(which node)" ]; then
    return 1
  fi

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz" ]; then
    # ${NODE_VERSION%%.*} -> 16.19.1 -> 16
    wget https://registry.npmmirror.com/-/binary/node/latest-v${NODE_VERSION%%.*}.x/node-v${NODE_VERSION}-linux-x64.tar.gz -O ${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz
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

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/firefox-${FIREFOX_VERSION}.tar.bz2" ]; then
    wget https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/zh-CN/firefox-${FIREFOX_VERSION}.tar.bz2 -O ${SOFTWARE_ADDONS_DIR}/firefox-${FIREFOX_VERSION}.tar.bz2
  fi

  if [ ! -d "${FIREFOX_HOME}" ]; then
    mkdir -p ${FIREFOX_HOME}
  fi

  tar --strip-components=1 -jxf ${SOFTWARE_ADDONS_DIR}/firefox-${FIREFOX_VERSION}.tar.bz2 -C ${FIREFOX_HOME}

  return 0
}

install_anaconda3(){

  if [ ${ENABLE_CONDA} -eq 0 ] ; then
    return 1
  fi

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

  # IDEA_BIN_ROOT_NAME="$(tar -tf /ideaIU-${IDEA_VERSION}.tar.gz | awk -F "/" '{print $1}' | sed -n '1p')"
  if [ ! -f "${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz" ]; then
    wget https://download.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz -O ${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz
  fi

  if [ ! -d "${IDEA_HOME}" ]; then
    mkdir -p ${IDEA_HOME}
  fi

  tar -xzf ${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz --strip-components=1 -C ${IDEA_HOME} && \
    echo "-javaagent:${XDG_SOFTWARE_HOME}/ja-netfilter-all/ja-netfilter.jar=jetbrains" >> ${IDEA_HOME}/bin/idea64.vmoptions && \
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" >> ${IDEA_HOME}/bin/idea64.vmoptions && \
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" >> ${IDEA_HOME}/bin/idea64.vmoptions

  JREBEL_SERVER_HOME=${XDG_SOFTWARE_HOME}/jrebel-license-server
  JA_NETFILTER_PATH=${XDG_SOFTWARE_HOME}/ja-netfilter-all

  if [ -d "${XDG_CONFIG_HOME}/JetBrains" ]; then
    find ${XDG_CONFIG_HOME}/JetBrains -name '*.lock' | xargs rm -f
  fi

  # Install ja-netfilter
  if [ -f "${CRACK_ADDONS_DIR}/ja-netfilter-all.zip" ] && [ ! -d ${JA_NETFILTER_PATH} ] ; then
    unzip -oq ${CRACK_ADDONS_DIR}/ja-netfilter-all.zip -d ${JA_NETFILTER_PATH}
  fi

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
install_dbeaver
install_node
install_firefox
install_anaconda3
install_idea

# vim:ft=sh:ts=4:sw=4:et:sts=4