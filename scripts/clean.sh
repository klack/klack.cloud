#!/bin/bash

if [ "$(basename "$PWD")" != "klack.cloud" ];then
  echo "Must be run from base project directory"
  exit 1
fi

if [ "$EUID" != 0 ]; then
  echo "Must be run as root"
  exit 1
fi

read -p "WARNING: Destructive! Ctrl-C Now"
source ./.env

#Shut down everything
echo "Shutting down services"
./down.sh

#Remove docker volumes
echo "Deleting docker volumes"
docker volume ls -q | grep '^klack-cloud_' | xargs -r docker volume rm -f

#Remove log, cloud, and data directories
echo "Removing Data and Log Directories"
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
rm -rfv ./data ./backups "${LOG_DIRS[@]}"

#Remove node_exporter
echo "Removing node_exporter"
killall node_exporter
rm -v /usr/local/bin/node_exporter

echo -e "\nCleaning complete"