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
  "$DIR_CLOUD_ROOT"
  "$DIR_CLOUD_ROOT/$CLOUD_USER"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Documents"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Notes"
  "$DIR_CLOUD_ROOT/$CLOUD_USER/Downloads"
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

#Setting Permissions
echo -e "\nSetting Permissions"
sudo chown -R 1000:1000 *
sudo chown -R 1000:1000 "${LOG_DIRS[@]}"
sudo chown -R 999:999 /var/log/cowrie

#Copy docker daemon
if [ ! -f /etc/docker/daemon.json ]; then
  cp -v ./config/docker/daemon.json /etc/docker/daemon.json
  echo "Docker daemon.json created"
else
  echo "Docker daemon.json already exists"
fi

#Generate hosts file
sed "s|\${HOST_IP}|${HOST_IP}|g; \
     s|\${INTERNAL_DOMAIN}|${INTERNAL_DOMAIN}|g" \
  ./config/hosts/hosts.template >./web/hosts.txt

sed "s|\${HOST_IP}|127.0.0.1|g; \
     s|\${INTERNAL_DOMAIN}|${INTERNAL_DOMAIN}|g" \
  ./config/hosts/hosts.template >./config/hosts/hosts

if ! grep -q "$INTERNAL_DOMAIN" /etc/hosts; then
  sh -c "cat ./config/hosts/hosts >> /etc/hosts"
  echo "Hosts file modified"
else
  echo "Hosts file already modified."
fi

#Update Grafana dashboard and default contact point
echo -e "\nSetting up Grafana"
cp ./config/grafana/dashboards/overview-dashboard.json.template ./config/grafana/dashboards/overview-dashboard.json
sed -i "s/\${NETWORK_INTERFACE}/${NETWORK_INTERFACE}/g" ./config/grafana/dashboards/overview-dashboard.json
sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" ./config/grafana/dashboards/overview-dashboard.json

cp ./config/grafana/provisioning/alerting/contact-points.yaml.template ./config/grafana/provisioning/alerting/contact-points.yaml
sed -i "s/\${GF_SMTP_FROM_ADDRESS}/${GF_SMTP_FROM_ADDRESS}/g" ./config/grafana/provisioning/alerting/contact-points.yaml

#Setup logrotate
echo -e "\nSetting up logrotate"
cp ./config/logrotate.d/* /etc/logrotate.d

#Install node_exporter
echo -e "\nSetting up node_exporter"
./scripts/install_node_exp.sh
nohup /usr/local/bin/node_exporter >/dev/null 2>&1 &

#Duplicati
echo -e "\nSetting up Duplicati"
cp ./config/duplicati/Duplicati-server.sqlite.new $DIR_DATA_ROOT/duplicati/Duplicati-server.sqlite

echo -e "\nPre run setup complete"
