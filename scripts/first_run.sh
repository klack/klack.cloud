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

#Generate home page
cp ./index.html.template index.html
chown 1000:1000 ./index.html
sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" index.html
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" index.html

echo -e "\nIndex.html created"

#Sample files
# echo  -e "\nDownloading sample files"
# wget https://download.blender.org/demo/movies/BBB/bbb_sunflower_1080p_30fps_normal.mp4.zip
# unzip bbb_sunflower_1080p_30fps_normal.mp4.zip -d ./data/klack.tv/library/movies
# rm bbb_sunflower_1080p_30fps_normal.mp4.zip
# wget -O ./data/sftpgoroot/data/cloud/Photos/starry_night.jpg https://upload.wikimedia.org/wikipedia/commons/c/cd/VanGogh-starry_night.jpg
# wget -O ./data/sftpgoroot/data/cloud/Photos/over_the_rhone.jpg https://upload.wikimedia.org/wikipedia/commons/9/94/Starry_Night_Over_the_Rhone.jpg
# wget -O ./data/sftpgoroot/data/cloud/Photos/vincent_van_gogh.jpg "https://upload.wikimedia.org/wikipedia/commons/4/4c/Vincent_van_Gogh_-_Self-Portrait_-_Google_Art_Project_%28454045%29.jpg"
