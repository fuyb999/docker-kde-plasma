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
export JAVA_HOME=${XDG_SOFTWARE_HOME}/jdk-${JDK_VERSION}
export DBEAVER_HOME=${XDG_SOFTWARE_HOME}/dbeaver-${DBEAVER_VERSION}
export NODE_HOME=${XDG_SOFTWARE_HOME}/node-v${NODE_VERSION}
export FIREFOX_HOME=${XDG_SOFTWARE_HOME}/firefox-${FIREFOX_VERSION}
export ANACONDA_HOME=${XDG_SOFTWARE_HOME}/anaconda3-${CONDA_VERSION}
export IDEA_HOME=${XDG_SOFTWARE_HOME}/ideaIU-${IDEA_VERSION}

env-store XDG_SOFTWARE_HOME
env-store ADDONS_DIR
env-store JAVA_HOME
env-store DBEAVER_HOME
env-store NODE_HOME
env-store FIREFOX_HOME
env-store ANACONDA_HOME
env-store IDEA_HOME

install_jdk(){
  if [ ${ENABLE_JDK} -eq 0 ]; then
   exit 0
  fi
  
  # 在 ENV 中定义的PATH 在此不生效
  if [ ! -f $HOME/.bashrc ] || [ -z "$(cat $HOME/.bashrc | grep 'JAVA_HOME')" ]; then
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> $HOME/.bashrc
  fi
  
  # 注意$HOME=/config 而不是 /root
  source $HOME/.bashrc
  if [ -n "$(which java)" ]; then
    exit 0
  fi
  
  if [ ! -f "${SOFTWARE_ADDONS_DIR}/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz" ]; then
    wget https://download.oracle.com/java/17/archive/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz -O ${SOFTWARE_ADDONS_DIR}/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz
  fi
  
  mkdir -p $JAVA_HOME
  tar --strip-components=1 -zxf ${SOFTWARE_ADDONS_DIR}/jdk-${JDK_VERSION}_linux-x64_bin.tar.gz -C $JAVA_HOME

  export PATH=${PATH}:${JAVA_HOME}/bin
  env-store PATH
}

install_dbeaver(){
  if [ ${ENABLE_DBEAVER} -eq 0 ] || [ -n "$(which dbeaver)" ]; then
    exit 0
  fi

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz" ]; then
    # ${DBEAVER_VERSION:3} -> ce_24.1.2 -> 24.1.2
   # wget https://dbeaver.com/downloads-ultimate/${DBEAVER_VERSION:3}/dbeaver-${DBEAVER_VERSION}_amd64.deb -O ${ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}_amd64.deb
   wget https://dbeaver.com/files/${DBEAVER_VERSION:3}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz -O ${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz
  fi

  mkdir -p $DBEAVER_HOME
  tar --strip-components=1 -zxf ${SOFTWARE_ADDONS_DIR}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz -C $DBEAVER_HOME

  # https://github.com/wgzhao/dbeaver-agent
  if [ -f "$ADDONS_DIR/crack/dbeaver/dbeaver-agent-1.0.jar" ] && [ ! -f "$DBEAVER_HOME/dbeaver-agent-1.0.jar" ]; then
    sudo cp $ADDONS_DIR/crack/dbeaver/dbeaver-agent-1.0.jar $DBEAVER_HOME/dbeaver-agent.jar
  fi

  DBEAVER_CONFIG=$DBEAVER_HOME/dbeaver.ini
  if [ -z "$(grep dbeaver-agent $DBEAVER_CONFIG)" ]; then
    sudo sed -i -e "/-vmargs/a\-javaagent:${DBEAVER_HOME}/dbeaver-agent.jar" $DBEAVER_CONFIG
  fi

  sudo rm -rf $DBEAVER_HOME/jre && sudo ln -s $JAVA_HOME $DBEAVER_HOME/jre
  $JAVA_HOME/bin/java -cp $ADDONS_DIR/crack/dbeaver/libs/\*:$DBEAVER_HOME/dbeaver-agent.jar \
     dev.misakacloud.dbee.License \
     --product=dbeaver \
     --type=ee \
     --version=24

  export PATH=${PATH}:${DBEAVER_HOME}/bin
  env-store PATH
}

install_node(){
  if [ ${ENABLE_NODE} -eq 0 ] || [ -n "$(which node)" ]; then
    exit 0
  fi

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz" ]; then
    # ${NODE_VERSION%%.*} -> 16.19.1 -> 16
    wget https://registry.npmmirror.com/-/binary/node/latest-v${NODE_VERSION%%.*}.x/node-v${NODE_VERSION}-linux-x64.tar.gz -O ${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz
  fi

  mkdir -p ${NODE_HOME}
  tar -C ${NODE_HOME} --strip-components=1 -zxf ${SOFTWARE_ADDONS_DIR}/node-v${NODE_VERSION}-linux-x64.tar.gz

  export PATH=${PATH}:${NODE_HOME}/bin
  env-store PATH

}

install_firefox(){
  if [ ${ENABLE_FIREFOX} -eq 0 ] || [ -n "$(which firefox)" ]; then
    exit 0
  fi

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/firefox-${FIREFOX_VERSION}.tar.bz2" ]; then
    wget https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/zh-CN/firefox-${FIREFOX_VERSION}.tar.bz2 -O ${SOFTWARE_ADDONS_DIR}/firefox-${FIREFOX_VERSION}.tar.bz2
  fi

  mkdir -p ${FIREFOX_HOME}
  tar -C ${FIREFOX_HOME} --strip-components=1 -jxf ${SOFTWARE_ADDONS_DIR}/firefox-${FIREFOX_VERSION}.tar.bz2

  export PATH=${PATH}:${FIREFOX_HOME}/bin
  env-store PATH
}

install_anaconda3(){

  if [ ${ENABLE_CONDA} -eq 0 ] ; then
    exit 0
  fi

  if [ -f $HOME/.bashrc ] ; then
    source $HOME/.bashrc
  fi

  if [ -n "$(which conda)" ]; then
    exit 0
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

  chmod 644 $HOME/.condarc

  if [ ! -f "${SOFTWARE_ADDONS_DIR}/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh" ]; then
    #apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6
    wget -nc https://repo.anaconda.com/archive/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh -O ${SOFTWARE_ADDONS_DIR}/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh
  fi

  if [ ! -d "$ANACONDA_HOME" ]; then
    bash ${SOFTWARE_ADDONS_DIR}/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh -b -p ${ANACONDA_HOME} -f
  fi

  # 调用 conda init 初始化conda 在 $HOME/.bashrc 添加初始化脚本 自动激活conda base
  chmod -R +x ${ANACONDA_HOME} && ${ANACONDA_HOME}/bin/conda init bash

  source $HOME/.bashrc
}

install_idea(){

  if [ -n "$(which ${IDEA_HOME}/bin/idea.sh)" ]; then
    exit 0
  fi

  # IDEA_BIN_ROOT_NAME="$(tar -tf /ideaIU-${IDEA_VERSION}.tar.gz | awk -F "/" '{print $1}' | sed -n '1p')"
  if [ ! -f "${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz" ]; then
    wget https://download.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz -O ${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz
  fi

  mkdir -p ${IDEA_HOME} && \
    tar -xzf ${SOFTWARE_ADDONS_DIR}/ideaIU-${IDEA_VERSION}.tar.gz --strip-components=1 -C ${IDEA_HOME} && \
    echo "-javaagent:${XDG_SOFTWARE_HOME}/ja-netfilter-all/ja-netfilter.jar=jetbrains" >> ${IDEA_HOME}/bin/idea64.vmoptions && \
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" >> ${IDEA_HOME}/bin/idea64.vmoptions && \
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" >> ${IDEA_HOME}/bin/idea64.vmoptions
}

install_jdk
install_dbeaver
install_node
install_firefox
install_anaconda3
install_idea

# vim:ft=sh:ts=4:sw=4:et:sts=4