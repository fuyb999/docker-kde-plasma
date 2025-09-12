#!/bin/false

# This file will be sourced in init.sh
# You can edit below here and make it do something useful

XDG_SOFTWARE_HOME=/opt/apps
PKG_HOME=$HOME/addons
DBEAVER_VERSION=ee-24.2.0
JAVA_HOME=$XDG_SOFTWARE_HOME/jdk-17.0.10

DBEAVER_HOME=${XDG_SOFTWARE_HOME}/dbeaver-${DBEAVER_VERSION}

install(){
  if [ -d "$DBEAVER_HOME" ] && [ -f "$DBEAVER_HOME/dbeaver" ]; then
    sudo ln -sf $DBEAVER_HOME/dbeaver /usr/local/bin/dbeaver
  fi
}

install
if [ ${ENABLE_DBEAVER} -eq 0 ] || [ -n "$(which dbeaver)" ]; then
  exit 0
fi

if [ ! -f "${PKG_HOME}/softwares/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz" ]; then
  # ${DBEAVER_VERSION:3} -> ce_24.1.2 -> 24.1.2
 # wget https://dbeaver.com/downloads-ultimate/${DBEAVER_VERSION:3}/dbeaver-${DBEAVER_VERSION}_amd64.deb -O ${PKG_HOME}/dbeaver-${DBEAVER_VERSION}_amd64.deb
 wget https://dbeaver.com/files/${DBEAVER_VERSION:3}/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz -O ${PKG_HOME}/softwares/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz
fi

mkdir -p $DBEAVER_HOME
#sudo dpkg -i ${PKG_HOME}/dbeaver-${DBEAVER_VERSION}_amd64.deb
tar --strip-components=1 -zxf ${PKG_HOME}/softwares/dbeaver-${DBEAVER_VERSION}-linux.gtk.x86_64.tar.gz -C $DBEAVER_HOME
install

# https://github.com/wgzhao/dbeaver-agent
if [ -f "$PKG_HOME/crack/dbeaver/dbeaver-agent-1.0.jar" ] && [ ! -f "$DBEAVER_HOME/dbeaver-agent-1.0.jar" ]; then
  sudo cp $PKG_HOME/crack/dbeaver/dbeaver-agent-1.0.jar $DBEAVER_HOME/dbeaver-agent.jar
fi

DBEAVER_CONFIG=$DBEAVER_HOME/dbeaver.ini
if [ -z "$(grep dbeaver-agent $DBEAVER_CONFIG)" ]; then
  sudo sed -i -e "/-vmargs/a\-javaagent:${DBEAVER_HOME}/dbeaver-agent.jar" $DBEAVER_CONFIG
fi

sudo rm -rf $DBEAVER_HOME/jre && sudo ln -s $JAVA_HOME $DBEAVER_HOME/jre
$JAVA_HOME/bin/java -cp $PKG_HOME/crack/dbeaver/libs/\*:$DBEAVER_HOME/dbeaver-agent.jar \
   dev.misakacloud.dbee.License \
   --product=dbeaver \
   --type=ee \
   --version=24

printf "Hello world!\n"
