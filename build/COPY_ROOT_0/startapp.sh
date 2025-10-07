#!/bin/bash

source /opt/ai-dock/etc/environment.sh

set -u # Treat unset variables as an error.

trap "exit" TERM QUIT INT

log() {
  echo "$*"
}

IDEA_CACHE_DIR=$HOME/.cache/idea
JREBEL_SERVER_PORT=${JREBEL_SERVER_PORT:-8848}
JREBEL_JAR_PATH=${JREBEL_SERVER_HOME}/jrebel-license-server.jar

[ -d "${IDEA_CACHE_DIR}" ] || mkdir "${IDEA_CACHE_DIR}"

get_pid_idea() {
  PID=UNSET
  if [ -f ${IDEA_CACHE_DIR}/idea.pid ]; then
      PID="$(cat ${IDEA_CACHE_DIR}/idea.pid)"
      # Make sure the saved PID is still running and is associated to
      if [ ! -f /proc/$PID/cmdline ] || ! cat /proc/$PID/cmdline | grep -qw "${IDEA_HOME}"; then
          PID=UNSET
      fi
  fi
  if [ "$PID" = "UNSET" ]; then
      PID="$(jps -l | grep -w "com.intellij.idea.Main" | grep -vw grep | tr -s ' ' | cut -d' ' -f1)"
      echo "$PID" > ${IDEA_CACHE_DIR}/idea.pid
  fi
  echo "${PID:-UNSET}"
}

is_idea_running() {
  [ "$(get_pid_idea)" != "UNSET" ]
}

start_idea() {

  # 禁用unicode,chttrans(简繁切换)插件，以解决ctrl+shift+f,ctrl+shift+u快捷键冲突
  if command -v fcitx5 > /dev/null; then
    fcitx5 --disable=unicode,chttrans,wayland,luaaddonloader -r -d --keep
  fi

  if command -v conda > /dev/null && [ -z "$(grep conda ~/.bashrc)" ]; then
    conda init bash
  fi

  if command -v podman > /dev/null; then
    sudo mount --make-rshared /
  fi

  if [ -z "$(git config --global user.name)" ]; then
    git config --global user.name "${GIT_USER:-$USER_NAME}"
  fi

  if [ -z "$(git config --global user.email)" ]; then
    git config --global user.email "${GIT_USER:-$USER_NAME}@gmail.com"
  fi

  if [ -n "$(echo "$STARTAPP" | grep idea)" ] && [ -f "$JREBEL_JAR_PATH" ] && [ -z "$(jps -l | grep -w $JREBEL_JAR_PATH | grep -vw grep)" ]; then
    nohup $JAVA_HOME/bin/java -Dfile.encoding=UTF-8 -Xmx300m -Xms100m -Duser.timezone=GMT+8 \
      -jar $JREBEL_JAR_PATH --server.port=$JREBEL_SERVER_PORT --logging.file.name=${IDEA_CACHE_DIR}/jrebel.log > /dev/null 2>&1 &
    echo "waiting for JRebel server... "
    sleep 1
    until curl -s -I http://localhost:$JREBEL_SERVER_PORT/get | grep -q "HTTP/1.1 200"; do sleep 3; done;
    echo "#################################################################################"
    curl --silent -X GET -H "Content-Type: application/json" http://localhost:$JREBEL_SERVER_PORT/get | jq -r '"#### JRebel 激活地址: \(.protocol)\(.licenseUrl)/\(.uuid) \n#### JRebel 激活邮箱: \(.mail)"'
    echo "#################################################################################"
  fi

  if [ -d "${XDG_CONFIG_HOME}/JetBrains" ]; then
    find "${XDG_CONFIG_HOME}/JetBrains" -name '*.lock' | xargs rm -f
  fi

  vglrun ${STARTAPP:-xterm} > ${IDEA_CACHE_DIR}/output.log 2>&1 &

}

kill_idea() {
  PID="$(get_pid_idea)"
  if [ "$PID" != "UNSET" ]; then
    log "Terminating IntelliJ IDEA..."
#        kill $PID
#        wait $PID
  fi
}

trap "kill_idea" EXIT

if ! is_idea_running; then
  log "IntelliJ IDEA not started yet.  Proceeding..."
  start_idea
fi

IDEA_NOT_RUNNING=0
while [ "$IDEA_NOT_RUNNING" -lt 60 ]
do
  if is_idea_running; then
    IDEA_NOT_RUNNING=0
  else
    IDEA_NOT_RUNNING="$(expr $IDEA_NOT_RUNNING + 1)"
  fi
  sleep 1
done

log "IntelliJ IDEA no longer running.  Exiting..."
