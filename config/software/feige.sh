#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/aura-dock/etc/environment.sh

if [ ! -f "${SOFTWARE_ADDONS_DIR}/Feige_for_64_Linux.tar.gz" ] || [ -n "$(which QIpmsg)" ]; then
  return 0
fi

sudo tar -zxf "${SOFTWARE_ADDONS_DIR}/Feige_for_64_Linux.tar.gz" -C "/usr/local/bin"

config_dir="$HOME/.feige"
config_file="$config_dir/.configIpmsg"
DB_FILE="$config_dir/ipmsg.db"

[ -d "$config_dir" ] || mkdir "$config_dir"

mac_address="$(ifconfig | grep ether | awk '{print $2}' | tr '[:lower:]' '[:upper:]' | tr ':' '-')"
ip_address="$( ifconfig | grep inet | awk '{print $2}' | head -n 1)"

echo "$USER_NAME" > "$config_file"
echo "2425" >> "$config_file"
echo "1" >> "$config_file"
echo "WorkGroup" >> "$config_file"
echo "$mac_address" >> "$config_file"

# 定义要插入的用户数据
USERNAME="$USER_NAME"
HOSTNAME="$(hostname)"
IP="$ip_address"
MAC="$mac_address"
WORKGROUP="WorkGroup"
LATESTTIME=0

# 创建表结构
sqlite3 "$DB_FILE" << 'EOF'
CREATE TABLE "user" ("username" TEXT NOT NULL , "hostname" TEXT NOT NULL , "ip" VARCHAR(15) NOT NULL , "mac" CHAR(17), "workgroup" TEXT NOT NULL , "latesttime" INTEGER NOT NULL  DEFAULT 0);
CREATE TABLE "record" ("mymac" VARCHAR(17) NOT NULL , "theirmac" VARCHAR(17), "ip" VARCHAR(15), "sender" TEXT NOT NULL , "date" TEXT NOT NULL , "msg" TEXT , "msgtype" BOOL NOT NULL);
CREATE TABLE "historyfiles" ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"theirmac" VARCHAR(17), "ip" VARCHAR(15), "sender" TEXT NOT NULL , "date" INTEGER NOT NULL , "filename" TEXT,"path" TEXT NOT NULL,"size" INTEGER ,"type"BOOL NOT NULL , "transstatus" BOOL NOT NULL);
CREATE TABLE "Sharefiles" ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"time" INTEGER, "type" INTEGER, "size" INTEGER , "name" TEXT NOT NULL , "path" TEXT NOT NULL,"MACList" TEXT);
CREATE TABLE "SharePassword" ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"sMac" TEXT NOT NULL, "PWLen" INTEGER, "Password" TEXT);
EOF

# 插入用户数据
sqlite3 "$DB_FILE" "INSERT INTO user (username, hostname, ip, mac, workgroup, latesttime) VALUES ('$USERNAME', '$HOSTNAME', '$IP', '$MAC', '$WORKGROUP', $LATESTTIME);"