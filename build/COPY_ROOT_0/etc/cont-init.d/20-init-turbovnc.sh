#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh

export PATH=$PATH:/opt/TurboVNC/bin

if ! command -v vncpasswd > /dev/null; then
  exit 0
fi

rm -rf /tmp/.X${DISPLAY:1}-lock /tmp/.X11-unix ~/.vnc
mkdir -p /tmp/.X11-unix
chmod 755 -R /tmp/.X11-unix

mkdir -p ~/.vnc/ ~/.dosbox
echo $USER_PASSWORD | vncpasswd -f > ~/.vnc/passwd
chmod 0600 ~/.vnc/passwd

vncserver ${DISPLAY} \
   -geometry ${DISPLAY_SIZEW}x${DISPLAY_SIZEH} \
   -depth ${DISPLAY_CDEPTH} \
   -auth ~/.vnc/passwd \
   -x509key /opt/caddy/tls/container.key \
   -x509cert /opt/caddy/tls/container.crt \
   -vgl

# vim:ft=sh:ts=4:sw=4:et:sts=4