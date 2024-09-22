#!/bin/bash -x

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
     ./config/hosts/hosts.template > ./config/hosts/hosts

sed "s|\${HOST_IP}|127.0.0.1|g; \
     s|\${INTERNAL_DOMAIN}|${INTERNAL_DOMAIN}|g" \
     ./config/hosts/hosts.template > ./web/hosts.txt

if ! grep -q ".klack.internal" /etc/hosts; then
  sh -c "cat ./config/hosts/hosts >> /etc/hosts"
  echo "Hosts file modified"
else
  echo "Hosts file already modified."
fi

#Update Grafana dashboard and default contact point
cp ./config/grafana/dashboards/overview-dashboard.json.template ./config/grafana/dashboards/overview-dashboard.json
sed -i "s/\${NETWORK_INTERFACE}/${DEFAULT_INTERFACE}/g" ./config/grafana/dashboards/overview-dashboard.json
cp ./config/grafana/provisioning/alerting/contact-points.yaml.template ./config/grafana/provisioning/alerting/contact-points.yaml
sed -i "s/\${GF_SMTP_FROM_ADDRESS}/${GF_SMTP_FROM_ADDRESS}/g" ./config/grafana/provisioning/alerting/contact-points.yaml

#Setup logrotate
cp ./config/logrotate.d/* /etc/logrotate.d

#Install node_exporter
echo -e "\nSetting up node_exporter"
./scripts/install_node_exp.sh
nohup /usr/local/bin/node_exporter >/dev/null 2>&1 &

#Duplicati
cp ./config/duplicati/Duplicati-server.sqlite.new $DIR_DATA_ROOT/duplicati/Duplicati-server.sqlite

#Generate home page
cp ./web/index.html.template ./web/index.html
sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${HOST_IP}/${HOST_IP}/g" ./web/index.html
echo -e "\nIndex.html created"

#Run first time app scripts
./config/sftpgo/provision.sh
./config/plex/provision.sh

#Download Sample Files
./scripts/download_samples.sh

#Setting Permissions
chown -R 1000:1000 ./
chown -R 1000:1000 "${LOG_DIRS[@]}"
chown -R 999:999 /var/log/cowrie