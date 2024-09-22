#!/bin/bash

source ./.env

#Setup directories
DATA_DIRS=(
    "$DIR_DATA_ROOT"
    "$DIR_DATA_ROOT/plex"
    "$DIR_DATA_ROOT/sftpgo"
    "$DIR_DATA_ROOT/transcode"
    "$DIR_DATA_ROOT/duplicati"
    "$DIR_BACKUPS"
    "$DIR_BACKUPS/Documents"
    "$DIR_BACKUPS/Notes"
    "$DIR_BACKUPS/Photos"
    "$DIR_CLOUD_ROOT"
    "$DIR_CLOUD_ROOT/$CLOUD_USER"
    "$DIR_CLOUD_ROOT/$CLOUD_USER/Documents"
    "$DIR_CLOUD_ROOT/$CLOUD_USER/Notes"
    "$DIR_CLOUD_ROOT/$CLOUD_USER/Photos"
    "$DIR_CLOUD_ROOT/$CLOUD_USER/Downloads"
    "$DIR_CLOUD_ROOT/$CLOUD_USER/Library/Movies"
    "$DIR_CLOUD_ROOT/$CLOUD_USER/Library/TV"
)
LOG_DIRS=(
    "/var/log/traefik"
    "/var/log/duplicati"
    "/var/log/dionaea"
    "/var/log/plex"
    "/var/log/radarr"
    "/var/log/sonarr"
    "/var/log/cowrie"
    "/var/log/plex/PMS Plugin Logs"
)
mkdir -vp "${DATA_DIRS[@]}" "${LOG_DIRS[@]}"
chown -vR 1000:1000 "${DATA_DIRS[@]}" "${LOG_DIRS[@]}"
chown -vR 999:999 /var/log/cowrie

#Setup logrotate
cp ./config/logrotate.d/* /etc/logrotate.d

#Install node_exporter
echo -e "\nSetting up node_exporter"
./scripts/install_node_exp.sh
nohup /usr/local/bin/node_exporter >/dev/null 2>&1 &

#Run first time app scripts
cp ./config/duplicati/Duplicati-server.sqlite.new $DIR_DATA_ROOT/duplicati/Duplicati-server.sqlite
./config/sftpgo/provision.sh
./config/plex/provision.sh

#Download Sample Files
./scripts/download_samples.sh

#Generate home page
cp ./index.html.template index.html
chown 1000:1000 ./index.html
sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" index.html
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" index.html

echo -e "\nIndex.html created"