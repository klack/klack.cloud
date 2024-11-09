#!/bin/bash

source ./.env

if [ "$EUID" != 0 ]; then
  echo "Must be run as root"
  exit 1
fi

#Setup directories
DATA_DIRS=(
  "$DIR_DATA_ROOT"
  "$DIR_DATA_ROOT/plex"
  "$DIR_DATA_ROOT/transcode"
  "$DIR_DATA_ROOT/duplicati"
  "$DIR_DATA_ROOT/immich/postgres"
  "$DIR_BACKUPS"
  "$DIR_BACKUPS/Documents"
  "$DIR_BACKUPS/Notes"
  "$DIR_BACKUPS/Photos"
  "$DIR_BACKUPS/Planner"
  "$DIR_CLOUD_ROOT"
  "$DIR_CLOUD_ROOT/$CLOUD_USER"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Documents"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Notes"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Planner"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Downloads"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Downloads/blackhole"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Library/Movies"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Library/TV"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Library/Photos"
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
touch ./config/promtail/positions.yaml

#Copy docker daemon
if [ ! -f /etc/docker/daemon.json ]; then
  cp -v ./config/docker/daemon.json /etc/docker/daemon.json
  echo "Docker daemon.json created"
else
  echo "Docker daemon.json already exists"
fi

cp ./config/grafana/provisioning/alerting/contact-points.yaml.template ./config/grafana/provisioning/alerting/contact-points.yaml
sed -i "s/\${GF_SMTP_FROM_ADDRESS}/${GF_SMTP_FROM_ADDRESS}/g" ./config/grafana/provisioning/alerting/contact-points.yaml

#Setup logrotate
echo -e "\nSetting up logrotate"
cp ./config/logrotate.d/* /etc/logrotate.d

#Install node_exporter
echo -e "\nSetting up node_exporter"
./scripts/install_node_exp.sh
nohup /usr/local/bin/node_exporter >/dev/null 2>&1 &

#Radicale
UUID=$(uuidgen)
mkdir -p "$DIR_CLOUD_ROOT/$CLOUD_USER/Planner/collections/collection-root/$CLOUD_USER/$UUID"
cp -r ./config/radicale/template/calendar/. $DIR_CLOUD_ROOT/$CLOUD_USER/Planner/collections/collection-root/$CLOUD_USER/$UUID
UUID=$(uuidgen)
mkdir -p "$DIR_CLOUD_ROOT/$CLOUD_USER/Planner/collections/collection-root/$CLOUD_USER/$UUID"
cp -r ./config/radicale/template/contacts/. $DIR_CLOUD_ROOT/$CLOUD_USER/Planner/collections/collection-root/$CLOUD_USER/$UUID
UUID=$(uuidgen)
mkdir -p "$DIR_CLOUD_ROOT/$CLOUD_USER/Planner/collections/collection-root/$CLOUD_USER/$UUID"
cp -r ./config/radicale/template/tasks/. $DIR_CLOUD_ROOT/$CLOUD_USER/Planner/collections/collection-root/$CLOUD_USER/$UUID

#Duplicati
echo -e "\nSetting up Duplicati"
cp ./config/duplicati/Duplicati-server.sqlite.new $DIR_DATA_ROOT/duplicati/Duplicati-server.sqlite

#Platform Specific
echo -e "\nRunning platform specific commands"
./scripts/platform.sh

#Setting Permissions
echo -e "\nSetting Permissions"
sudo chown -R 1000:1000 *
sudo chown -R 1000:1000 "${LOG_DIRS[@]}"
sudo chown -R 999:999 /var/log/cowrie

echo -e "\nPre-run setup complete"