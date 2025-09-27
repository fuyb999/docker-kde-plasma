#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

function init_cleanup() {
    printf "Cleaning up...\n"
    rm -rf /tmp/* $HOME/.vnc
    # Each running process should have its own cleanup routine
}

trap init_cleanup SIGTERM SIGINT SIGQUIT

STAGE=init
MIN_LOG_PREFIX_LENGTH=12

function log() {
    case "$1" in
        :::*)
            echo "$*" | cut -c 4-
            ;;
        *)
            printf "[%-${MIN_LOG_PREFIX_LENGTH}s] " "${STAGE}"
            echo "$*"
            ;;
    esac
}

function log_script() {
    while IFS= read -r output; do
        case "${output}" in
            :::*) log "${output}" ;;
            *) log "$1: ${output}" ;;
        esac
    done
}

function set_min_log_prefix_length() {
    find /etc/services.d -maxdepth 1 -type d | while read -r dir; do
        if [ "${#dir}" -gt "${MIN_LOG_PREFIX_LENGTH}" ]; then
            MIN_LOG_PREFIX_LENGTH="${#dir}"
        fi
    done
}

function valid_env_var_name() {
    case "$1" in
        *[!a-zA-Z0-9_]* | [0-9]*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

function init_run_scripts() {
    log "executing container initialization scripts..."
    if [ -d /etc/cont-init.d ]; then
        find /etc/cont-init.d -maxdepth 1 -type f | sort | while read -r f; do
            fname="$(basename "${f}")"

            if [ ! -x "${f}" ]; then
                echo "WARNING: not executable, ignoring." | log_script "${fname}"
                continue
            fi

            echo "executing..." | log_script "${fname}"

            rc_file="$(mktemp)"
            (
                set +e
                sudo -E -u \#${USER_ID} ${f} 2>&1
                echo $? > "${rc_file}"
            ) | log_script "${fname}"
            read -r rc < "${rc_file}"
            rm -f "${rc_file}"

            if [ "${rc}" -eq 0 ]; then
                echo "terminated successfully." | log_script "${fname}"
            else
                echo "terminated with error ${rc}." | log_script "${fname}"
                exit "${rc}"
            fi
        done
    fi
    log "all container initialization scripts executed."
}

function init_set_envs() {
    # Common services that we don't want in serverless mode
    if [[ ${SERVERLESS,,} == "true" && -z $SUPERVISOR_NO_AUTOSTART ]]; then
        export SUPERVISOR_NO_AUTOSTART="caddy,cloudflared,jupyter,quicktunnel,serviceportal,sshd,syncthing"
    fi

    for i in "$@"; do
        IFS="=" read -r key val <<< "$i"
        if [[ -n $key && -n $val ]]; then
            export "${key}"="${val}"
            # Normalise *_FLAGS to *_ARGS because of poor original naming
            if [[ $key == *_FLAGS ]]; then
                args_key="${key%_FLAGS}_ARGS"
                export "${args_key}"="${val}"
            fi
        fi
    done
    
    # TODO: This does not handle cases where the tcp and udp port are both opened
    # Re-write envs; 
    ## 1) Strip quotes & replace ___ with a space
    ## 2) re-write cloud out-of-band ports
    while IFS='=' read -r -d '' key val; do
        if [[ $key == *"PORT_HOST" && $val -ge 70000 ]]; then
            declare -n vast_oob_tcp_port=VAST_TCP_PORT_${val}
            declare -n vast_oob_udp_port=VAST_UDP_PORT_${val}
            declare -n runpod_oob_tcp_port=RUNPOD_TCP_PORT_${val}
            if [[ -n $vast_oob_tcp_port ]]; then
                export $key=$vast_oob_tcp_port
            elif [[ -n $vast_oob_udp_port ]]; then
                export $key=$vast_oob_udp_port
            elif [[ -n $runpod_oob_tcp_port ]]; then
                export $key=$runpod_oob_tcp_port
            fi
        else
            export "${key}"="$(init_strip_quotes "${val//___/' '}")"
        fi
    done < <(env -0)
}

init_set_web_config() {
  # Handle cloud provider auto login
  
  if [[ -z $CADDY_AUTH_COOKIE_NAME ]]; then
      export CADDY_AUTH_COOKIE_NAME=ai_dock_$(echo $RANDOM | md5sum | head -c 8)_token
  fi
  # Vast.ai
  if [[ $(env | grep -i vast) && -n $OPEN_BUTTON_TOKEN ]]; then
      if [[ -z $WEB_TOKEN ]]; then
          export WEB_TOKEN="${OPEN_BUTTON_TOKEN}"
      fi
      if [[ -z $WEB_USER ]]; then
          export WEB_USER=vastai
      fi
      if [[ -z $WEB_PASSWORD || $WEB_PASSWORD == "password" ]]; then
          export WEB_PASSWORD="${OPEN_BUTTON_TOKEN}"
      fi
      # Vast.ai TLS certificates
      rm -f /opt/caddy/tls/container.*
      ln -sf /etc/instance.crt /opt/caddy/tls/container.crt
      ln -sf /etc/instance.key /opt/caddy/tls/container.key
  fi
  
  if [[ -z $WEB_USER ]]; then
      export WEB_USER=user
  fi

  if [[ -z $WEB_PASSWORD ]]; then
      export WEB_PASSWORD="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)"
  fi

  if [[ -n "$(which caddy)" ]]; then
     export WEB_PASSWORD_B64="$(caddy hash-password -p $WEB_PASSWORD)"
  fi

  if [[ -z $WEB_TOKEN ]]; then
      export WEB_TOKEN="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
  fi

  if [[ -n $DISPLAY && -z $COTURN_PASSWORD ]]; then
        export COTURN_PASSWORD="auto_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
  fi
}

function init_count_gpus() {
    nvidia_dir="/proc/driver/nvidia/gpus/"
    if [[ -z $GPU_COUNT ]]; then
        if [[ "$XPU_TARGET" == "NVIDIA_GPU" && -d "$nvidia_dir" ]]; then
            GPU_COUNT="$(echo "$(find "$nvidia_dir" -maxdepth 1 -type d | wc -l)"-1 | bc)"
        elif [[ "$XPU_TARGET" == "AMD_GPU" ]]; then
            GPU_COUNT=$(lspci | grep -i -e "VGA compatible controller" -e "Display controller" | grep -i "AMD" | wc -l)
        else
            GPU_COUNT=0
        fi
        export GPU_COUNT
    fi
}

function init_count_quicktunnels() {
    if [[ ${CF_QUICK_TUNNELS,,} == "false" ]]; then
        export CF_QUICK_TUNNELS_COUNT=0
    else
        export CF_QUICK_TUNNELS_COUNT=$(grep -l "QUICKTUNNELS=true" /opt/ai-dock/bin/supervisor-*.sh | wc -l)
        if [[ -z $TUNNEL_TRANSPORT_PROTOCOL ]]; then
            export TUNNEL_TRANSPORT_PROTOCOL=http2
        fi
    fi
}

init_sync_opt() {
    WORKSPACE=${WORKSPACE:-"$HOME"}
    # Applications at /opt *always* get synced to a mounted workspace
    if [[ $WORKSPACE_MOUNTED = "true" ]]; then
        printf "Opt sync start: %s\n" "$(date +"%x %T.%3N")" >> /var/log/timing_data
        IFS=: read -r -d '' -a path_array < <(printf '%s:\0' "$OPT_SYNC")
        for item in "${path_array[@]}"; do
            opt_dir="/opt/${item}"
            if [[ ! -d $opt_dir || $opt_dir = "/opt/" || $opt_dir = "/opt/ai-dock" ]]; then
                continue
            fi

            ws_dir="${WORKSPACE}${item}"
            archive="${item}.tar"

            # remove old backup links (depreciated)
            rm -f "${ws_dir}-link"

            # Restarting stopped container
            if [[ -d $ws_dir && -L $opt_dir ]]; then
                printf "%s already symlinked to %s\n" $opt_dir $ws_dir
                continue
            fi

            # Reset symlinks first
            if [[ -L $opt_dir ]]; then rm -f "$opt_dir"; fi
            if [[ -L $ws_dir ]]; then rm -f "$ws_dir"; fi

            # Sanity check
            # User broke something - Container requires tear-down & restart
            if [[ ! -d $opt_dir && ! -d $ws_dir ]]; then
                printf "\U274C Critical directory ${opt_dir} is missing without a backup!\n"
                continue
            fi

            # Copy & delete directories
            # Found a Successfully copied directory
            if [[ -d $ws_dir && -f $ws_dir/.move_complete ]]; then
                # Delete the container copy
                if [[ -d $opt_dir && ! -L $opt_dir ]]; then
                    rm -rf "$opt_dir"
                fi
            # No/incomplete workspace copy
            else
                printf "Moving %s to %s\n" "$opt_dir" "$ws_dir"

                while sleep 10; do printf "Waiting for %s application sync...\n" "$item"; done &
                    printf "Creating archive of %s...\n" "$opt_dir"
                    (cd /opt && tar -cf "${archive}" "${item}" --no-same-owner --no-same-permissions)
                    printf "Transferring %s archive to %s...\n" "${item}" "${WORKSPACE}"
                    mv -f "/opt/${archive}" "${WORKSPACE}"
                    printf "Extracting %s archive to %s...\n" "${item}" "${WORKSPACE}${item}"
                    tar -xf "${WORKSPACE}${archive}" -C "${WORKSPACE}" --keep-newer-files --no-same-owner --no-same-permissions
                    rm -f "${WORKSPACE}${archive}"
                # Kill the progress printer
                kill $!
                printf "Moved %s to %s\n" "$opt_dir" "$ws_dir"
                printf 1 > $ws_dir/.move_complete
            fi

            # Create symlinks
            # Use workspace version
            if [[ -f "${ws_dir}/.move_complete" ]]; then
                printf "Creating symlink to %s at %s\n" $ws_dir $opt_dir
                rm -rf "$opt_dir"
                ln -s "$ws_dir" "$opt_dir"
            else
                printf "Expected to find %s but it's missing.  Using %s instead\n" "${ws_dir}/.move_complete" "$opt_dir"
            fi
        done
        printf "Opt sync complete: %s\n" "$(date +"%x %T.%3N")" >> /var/log/timing_data
  fi
}

function init_toggle_supervisor_autostart() {
    if [[ -z $CF_TUNNEL_TOKEN ]]; then
        SUPERVISOR_NO_AUTOSTART="${SUPERVISOR_NO_AUTOSTART:+$SUPERVISOR_NO_AUTOSTART,}cloudflared"
    fi

    IFS="," read -r -a no_autostart <<< "$SUPERVISOR_NO_AUTOSTART"
    for service in "${no_autostart[@]}"; do
        file="/etc/supervisor/supervisord/conf.d/${service,,}.conf"
        if [[ -f $file ]]; then
            sed -i '/^autostart=/c\autostart=false' $file
        fi
    done
}

# This could be much better...
function init_strip_quotes() {
    if [[ -z $1 ]]; then
        printf ""
    elif [[ ${1:0:1} = '"' && ${1:(-1)} = '"' ]]; then
        sed -e 's/^.//' -e 's/.$//' <<< "$1"
    elif [[ ${1:0:1} = "'" && ${1:(-1)} = "'" ]]; then
        sed -e 's/^.//' -e 's/.$//' <<< "$1"
    else
        printf "%s" "$1"
    fi
}

function init_debug_print() {
    if [[ -n $DEBUG ]]; then
        printf "\n\n\n---------- DEBUG INFO ----------\n\n"
        printf "env output...\n\n"
        env
        printf "\n--------------------------------------------\n"
        printf "authorized_keys...\n\n"
        cat /root/.ssh/authorized_keys
        printf "\n--------------------------------------------\n"
        printf "/opt/ai-dock/etc/environment.sh...\n\n"
        cat /opt/ai-dock/etc/environment.sh
        printf "\n--------------------------------------------\n"
        printf ".bashrc...\n\n"
        cat /root/.bashrc
        printf "\n---------- END DEBUG INFO---------- \n\n\n"
    fi
}

umask 002
source /opt/ai-dock/etc/environment.sh
ldconfig

STAGE=envs-init
init_set_envs "$@"

# Invoke initialization scripts.
STAGE=cont-init
/etc/cont-init.d/00-init-create-user.sh
init_run_scripts

# Finally, invoke the process supervisor.
STAGE=init

if ! grep -q '^cinit:' /etc/group; then
  groupadd -g 72 cinit
fi

set --
set -- "$@" "--progname"
set -- "$@" "supervisor"
set -- "$@" "--services-gracetime"
set -- "$@" "${SERVICES_GRACETIME:-5000}"
set -- "$@" "--default-service-uid"
set -- "$@" "${USER_ID}"
set -- "$@" "--default-service-gid"
set -- "$@" "${GROUP_ID}"
if [ ${CONTAINER_DEBUG:-0} -eq 1 ]; then
    set -- "$@" "--debug"
fi

log "giving control to process supervisor."
exec /opt/base/sbin/cinit "$@"

# vim:ft=sh:ts=4:sw=4:et:sts=4


