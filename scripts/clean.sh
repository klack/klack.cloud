#!/bin/bash

source ./.env

if [ "$(basename "$PWD")" != "klack.cloud" ];then
  echo "Must be run from base project directory"
  exit 1
fi

if [ "$EUID" != 0 ]; then
  echo "Must be run as root"
  exit 1
fi

read -p "WARNING: Destructive! Ctrl-C to quit now or press enter to proceed: "

#Shut down everything
echo "Shutting down services"
./stop.sh

chown -R 1000:1000 *

#Remove docker volumes
echo "Deleting docker volumes"
docker volume ls -q | grep '^klack-cloud_' | grep -v '^klack-cloud_acme$' | xargs -r docker volume rm -f

#Remove log, cloud, and data directories
echo "Removing default data and log directories"
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
rm -rfv ./cloud-metadata ./backups "${LOG_DIRS[@]}"

#Remove node_exporter
echo "Removing node_exporter"
killall node_exporter
rm -v /usr/local/bin/node_exporter

# Clean crontab
cp /etc/crontab /etc/crontab.bak #Backup original file
sed -i '/node_exporter/d' /etc/crontab #Remove node_exporter
sed -i '/build_images.sh/d' /etc/crontab #Remove arm64 image builder
echo "Entries containing 'node_exporter' have been removed from /etc/crontab."

echo -e "\nCleaning complete"
