#!/bin/bash

source ./.env

#Setup directories
DATA_DIRS=(
    "./data/transcode"
    "./data/backups"
    "./data/backups/Documents"
    "./data/backups/Notes"
    "./data/backups/Photos "
    "./cloud/clouduser/Documents"
    "./cloud/clouduser/Notes"
    "./cloud/clouduser/Photos"
    "./cloud/clouduser/Downloads"
    "./cloud/clouduser/Library/Movies"
    "./cloud/clouduser/Library/TV"
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
./config/sftpgo/provision.sh

#Download Sample Files
./scripts/download_samples.sh

#Generate home page
cp ./index.html.template index.html
chown 1000:1000 ./index.html
sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" index.html
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" index.html

echo -e "\nIndex.html created"