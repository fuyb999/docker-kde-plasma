#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

#set -e # Exit immediately if a command exits with a non-zero status.
source /opt/ai-dock/etc/environment.sh

sudo mkdir -p /tmp/.X11-unix
sudo chmod 777 -R /tmp/.X11-unix

mkdir -p ~/.vnc/ ~/.dosbox
echo $USER_PASSWORD | /opt/TurboVNC/bin/vncpasswd -f > ~/.vnc/passwd
chmod 0600 ~/.vnc/passwd

/opt/TurboVNC/bin/vncserver ${DISPLAY} \
   -geometry ${DISPLAY_SIZEW}x${DISPLAY_SIZEH} \
   -depth ${DISPLAY_CDEPTH} \
   -auth ~/.vnc/passwd \
   -x509key /opt/caddy/tls/container.key \
   -x509cert /opt/caddy/tls/container.crt \
   -vgl

#/usr/bin/openbox --config-file /etc/openbox/rc.xml --startup /opt/TurboVNC/bin/xstartup.turbovnc

# vim:ft=sh:ts=4:sw=4:et:sts=4