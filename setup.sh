#!/bin/bash

# Check if the script is run by root (or sudo)
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

#Setup folders and perms
DATA_DIRS=(
  "./data/backups"
  "./data/joplin"
  "./data/klack.tv"
  "./data/photos"
  "./data/sftpgoroot/data/cloud"
  "./data/transcode"
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

#Shut down everything
./down.sh
killall node_exporter

#Clean option
if [[ "$1" == "--clean" ]]; then
  echo "Deleting docker volumes"
  docker volume ls -q | grep '^klack-cloud_' | xargs -r docker volume rm -f
  rm -rf "${DATA_DIRS[@]}" "${LOG_DIRS[@]}"
  rm /usr/local/bin/node_exporter
fi

#Install node_exporter
./scripts/install_node_exp.sh

#Setup directories
mkdir -vp "${DATA_DIRS[@]}" "${LOG_DIRS[@]}"
chown -vR 1000:1000 "${DATA_DIRS[@]}" "${LOG_DIRS[@]}"
chown -vR 999:999 /var/log/cowrie
cp ./config/logrotate.d/* /etc/logrotate.d

#Copy docker daemon
if [ ! -f /etc/docker/daemon.json ]; then
    cp -v ./config/docker/daemon.json /etc/docker/daemon.json
    echo "Docker daemon.json created"
else
    echo "Docker daemon.json already exists"
fi

#Edit hosts file
if ! grep -q ".klack.internal" /etc/hosts; then
    sh -c "cat ./config/hosts/hosts >> /etc/hosts"
    echo "Hosts file modified"
else 
    echo "Hosts file already modified."
fi

#Prompt for info
DEFAULT_HOST_IP=$(hostname -I | awk '{print $1}')
DEFUALT_GATEWAY=$(ip route | grep default | awk '{print $3}')
DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}')
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
read -p "Enter external domain: " EXTERNAL_DOMAIN
read -s -p "Enter password: " PASSWORD
echo
read -s -p "Enter password again: " PASSWORD_CONFIRM
echo
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi
read -p "Visit https://plex.tv/claim and paste claim token: " PLEX_CLAIM
read -p "Press enter for default network interface [$DEFAULT_INTERFACE]: " HOST_IP
read -p "Press enter for default host IP [$DEFAULT_HOST_IP]: " HOST_IP
read -p "Press enter for default gateway [$DEFUALT_GATEWAY]: " GATEWAY
HOST_IP=${HOST_IP:-"$DEFAULT_HOST_IP"}
GATEWAY=${GATEWAY:-"$DEFUALT_GATEWAY"}
NETWORK=$(echo "$GATEWAY" | cut -d '.' -f 1-3)
ESCAPED_PASSWORD=$(printf '%s\n' "$PASSWORD" | sed 's/\([\"$]\)/\\\1/g')
MARIADB_PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#%' | head -c 16)
MARIADB_ROOT_PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#%' | head -c 16)
SONARR_API_KEY=$(head -c 16 /dev/urandom | xxd -p)
RADARR_API_KEY=$(head -c 16 /dev/urandom | xxd -p)

#Update .env file
cp ./.env.template ./.env
sed -i "s|^TZ=.*|TZ=$TIMEZONE|" .env
sed -i "s|^EXTERNAL_DOMAIN=.*|EXTERNAL_DOMAIN=$EXTERNAL_DOMAIN|" .env
sed -i "s|^PLEX_CLAIM=.*|PLEX_CLAIM=$PLEX_CLAIM|" .env
sed -i "s|^BASIC_AUTH_PASS=.*|BASIC_AUTH_PASS=\"$ESCAPED_PASSWORD\"|" .env
sed -i "s|^NODE_EXPORTER_PASS=.*|NODE_EXPORTER_PASS=\"$ESCAPED_PASSWORD\"|" .env
sed -i "s|^PHOTOPRISM_ADMIN_PASSWORD=.*|PHOTOPRISM_ADMIN_PASSWORD=\"$ESCAPED_PASSWORD\"|" .env
sed -i "s|^MARIADB_ROOT_PASSWORD=.*|MARIADB_ROOT_PASSWORD=\"$MARIADB_ROOT_PASSWORD\"|" .env
sed -i "s|^MARIADB_PASSWORD=.*|MARIADB_PASSWORD=\"$MARIADB_PASSWORD\"|" .env
sed -i "s|^HOST_IP=.*|HOST_IP=$HOST_IP|" .env
sed -i "s|^HONEYPOT_GATEWAY=.*|HONEYPOT_GATEWAY=$GATEWAY|" .env
sed -i "s|^NETWORK_INTERFACE=.*|NETWORK_INTERFACE=$DEFAULT_INTERFACE|" .env
sed -i "s|^HOST_IP=.*|HOST_IP=$HOST_IP|" .env
sed -i "s|^SONARR_API_KEY=.*|SONARR_API_KEY=\"$SONARR_API_KEY\"|" .env
sed -i "s|^RADARR_API_KEY=.*|RADARR_API_KEY=\"$RADARR_API_KEY\"|" .env
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" .env
sed -i "s/\${NETWORK}/${NETWORK}/g" .env
echo ".env file generated"

#Update dashboard with network interface
cp ./config/grafana/overview-dashboard.json.template ./config/grafana/overview-dashboard.json
sed -i "s/\${NETWORK_INTERFACE}/${DEFAULT_INTERFACE}/g" ./config/grafana/overview-dashboard.json

#Set qBittorrent password
cp ./config/qbittorrent/qBittorrent.conf.template ./config/qbittorrent/qBittorrent.conf
PASSWORD_PBKDF2="$(docker run --rm -v ./scripts:/app -w /app python:3.10-slim python generate_pkbdf2.py $PASSWORD)"
sed -i "s#\${PASSWORD_PBKDF2}#${PASSWORD_PBKDF2}#g" ./config/qbittorrent/qBittorrent.conf

#Set Servarr api keys
cp ./config/radarr/config.xml.template ./config/radarr/config.xml
sed -i "s/\${API_KEY}/${RADARR_API_KEY}/g" ./config/radarr/config.xml
cp ./config/sonarr/config.xml.template ./config/sonarr/config.xml
sed -i "s/\${API_KEY}/${SONARR_API_KEY}/g" ./config/sonarr/config.xml

#Generate htpassword
docker run --rm httpd:latest htpasswd \
  -Bbn admin "$PASSWORD" > \
  ./config/traefik/htpasswd && echo "htpassword generated"

nohup /usr/local/bin/node_exporter > /dev/null 2>&1 & 
echo "node_exporter started"
echo "First-time Setup complete"
echo "Type ./up.sh to launch"