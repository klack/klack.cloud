#!/bin/bash -x

if [ "$(basename "$PWD")" != "klack.cloud" ];then
  echo "Must be run from base project directory"
  exit 1
fi

source ./.env

read -p "WARNING: Destructive! Ctrl-C Now"

#Shut down everything
echo "Shutting down services"
./scripts/down.sh

echo "Deleting docker volumes"
docker volume ls -q | grep '^klack-cloud_' | xargs -r docker volume rm -f

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
rm -v ./config/sftpgo/homeuser/sftpgo.db
rm -rfv ./data ./cloud "${LOG_DIRS[@]}"

echo "Removing node_exporter"
killall node_exporter
rm -v /usr/local/bin/node_exporter

echo -e "\nCleaning complete"