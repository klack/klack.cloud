#!/bin/bash

# Check if the script is run by root (or sudo)
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

#Setup folders and perms
DATA_DIRS=(
  "./data/backups"
  "./data/klack.tv"
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
./scripts/down.sh
killall node_exporter

#Clean option
if [[ "$1" == "--clean" ]]; then
  read -p "WARNING: Destructive! Ctrl-C Now"
  echo "Deleting docker volumes"
  docker volume ls -q | grep '^klack-cloud_' | xargs -r docker volume rm -f
  echo "Removing Data and Log Directories"
  rm -rfv ./data "${LOG_DIRS[@]}"
  rm -v ./config/sftpgo/homeuser/sftpgo.db
  echo "Removing node_exporter"
  rm -v /usr/local/bin/node_exporter
  exit 1
fi

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

#.env file generation
cp -p ./.env.template ./.env
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
sed -i "s|^TZ=.*|TZ=$TIMEZONE|" .env

#Password Prompting
echo
read -p "Enter external domain: " EXTERNAL_DOMAIN
read -s -p "Create an admin password: " PASSWORD
echo
read -s -p "Enter password again: " PASSWORD_CONFIRM
echo
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi
read -s -p "Create a cloud password: " CLOUD_PASSWORD
echo
read -s -p "Enter password again: " CLOUD_PASSWORD_CONFIRM
echo
if [ "$CLOUD_PASSWORD" != "$CLOUD_PASSWORD_CONFIRM" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi
if [ "$PASSWORD" == "$CLOUD_PASSWORD" ]; then
    echo "Admin and cloud password cannot be the same. Exiting."
    exit 1
fi

#External Domain
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" .env

#Passwords
ESCAPED_PASSWORD=$(printf '%s\n' "$PASSWORD" | sed 's/\([\"$]\)/\\\1/g')
ESCAPED_CLOUD_PASSWORD=$(printf '%s\n' "$CLOUD_PASSWORD" | sed 's/\([\"$]\)/\\\1/g')
sed -i "s|^BASIC_AUTH_PASS=.*|BASIC_AUTH_PASS=\"$ESCAPED_PASSWORD\"|" .env
sed -i "s|^CLOUD_PASS=.*|CLOUD_PASS=\"$ESCAPED_CLOUD_PASSWORD\"|" .env

#Generate htpassword
docker run --rm httpd:latest htpasswd \
  -Bbn admin "$PASSWORD" > \
  ./config/traefik/htpasswd && echo "htpassword generated"

#Photoprism
MARIADB_PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#%' | head -c 16)
MARIADB_ROOT_PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#%' | head -c 16)
sed -i "s|^MARIADB_ROOT_PASSWORD=.*|MARIADB_ROOT_PASSWORD=\"$MARIADB_ROOT_PASSWORD\"|" .env
sed -i "s|^MARIADB_PASSWORD=.*|MARIADB_PASSWORD=\"$MARIADB_PASSWORD\"|" .env

#Sonarr / Radarr
SONARR_API_KEY=$(head -c 16 /dev/urandom | xxd -p)
RADARR_API_KEY=$(head -c 16 /dev/urandom | xxd -p)
sed -i "s|^SONARR_API_KEY=.*|SONARR_API_KEY=\"$SONARR_API_KEY\"|" .env
sed -i "s|^RADARR_API_KEY=.*|RADARR_API_KEY=\"$RADARR_API_KEY\"|" .env

#Plex
echo -e "\nPlex Setup"
read -p "Visit https://plex.tv/claim and paste claim token: " PLEX_CLAIM
sed -i "s|^PLEX_CLAIM=.*|PLEX_CLAIM=$PLEX_CLAIM|" .env

#Set qBittorrent password
cp -p ./config/qbittorrent/qBittorrent.conf.template ./config/qbittorrent/qBittorrent.conf
PASSWORD_PBKDF2="$(docker run --rm -v ./scripts:/app -w /app python:3.10-slim python generate_pkbdf2.py "$PASSWORD")"
sed -i "s#\${PASSWORD_PBKDF2}#${PASSWORD_PBKDF2}#g" ./config/qbittorrent/qBittorrent.conf

#Set Servarr api keys
cp -p ./config/radarr/config.xml.template ./config/radarr/config.xml
sed -i "s/\${API_KEY}/${RADARR_API_KEY}/g" ./config/radarr/config.xml
cp ./config/sonarr/config.xml.template ./config/sonarr/config.xml
sed -i "s/\${API_KEY}/${SONARR_API_KEY}/g" ./config/sonarr/config.xml

#Copy fresh duplicati db
cp ./config/duplicati/Duplicati-server.sqlite.new ./config/duplicati/Duplicati-server.sqlite

#Notifications
DEFAULT_MAIL_HOST=smtp.protonmail.ch
DEFAULT_MAIL_PORT=587
DEFAULT_MAIL_FROM=notify@$EXTERNAL_DOMAIN
DEFAULT_MAIL_USER=notify@$EXTERNAL_DOMAIN
echo -e "\nEmail Notifications:"
read -p "Enter your ISP mail server address, or press enter for Proton Mail [$DEFAULT_MAIL_HOST]: " GF_SMTP_HOST
read -p "Enter your ISP mail server port, or press enter for Proton Mail [$DEFAULT_MAIL_PORT]: " GF_SMTP_PORT
read -p "Enter your from address [$DEFAULT_MAIL_FROM]:" GF_SMTP_FROM_ADDRESS
read -p "Enter your SMTP user  [notify@$EXTERNAL_DOMAIN]" GF_SMTP_USER
read -s -p "Enter your SMTP password:" GF_SMTP_PASSWORD
GF_SMTP_HOST=${GF_SMTP_HOST:-"$DEFAULT_MAIL_HOST"}
GF_SMTP_PORT=${GF_SMTP_PORT:-"$DEFAULT_MAIL_PORT"}
GF_SMTP_FROM_ADDRESS=${GF_SMTP_FROM_ADDRESS:-"$DEFAULT_MAIL_FROM"}
GF_SMTP_USER=${GF_SMTP_USER:-"$DEFAULT_MAIL_USER"}
sed -i "s|^GF_SMTP_FROM_ADDRESS=.*|GF_SMTP_FROM_ADDRESS=$GF_SMTP_FROM_ADDRESS|" .env
sed -i "s|^GF_SMTP_USER=.*|GF_SMTP_USER=$GF_SMTP_USER|" .env
sed -i "s|^GF_SMTP_PASSWORD=.*|GF_SMTP_PASSWORD=$GF_SMTP_PASSWORD|" .env
sed -i "s/\${GF_SMTP_HOST}/${GF_SMTP_HOST}/g" .env
sed -i "s/\${GF_SMTP_PORT}/${GF_SMTP_PORT}/g" .env

#Honeypot
echo -e "\n\nHoneypot Setup:"
DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}')
DEFAULT_HOST_IP=$(hostname -I | awk '{print $1}')
DEFUALT_GATEWAY=$(ip route | grep default | awk '{print $3}')
read -p "Press enter for default network interface [$DEFAULT_INTERFACE]: " HOST_IP
read -p "Press enter for default host IP [$DEFAULT_HOST_IP]: " HOST_IP
read -p "Press enter for default gateway [$DEFUALT_GATEWAY]: " GATEWAY
HOST_IP=${HOST_IP:-"$DEFAULT_HOST_IP"}
GATEWAY=${GATEWAY:-"$DEFUALT_GATEWAY"}
NETWORK=$(echo "$GATEWAY" | cut -d '.' -f 1-3)
sed -i "s|^HOST_IP=.*|HOST_IP=$HOST_IP|" .env
sed -i "s|^HONEYPOT_GATEWAY=.*|HONEYPOT_GATEWAY=$GATEWAY|" .env
sed -i "s|^NETWORK_INTERFACE=.*|NETWORK_INTERFACE=$DEFAULT_INTERFACE|" .env
sed -i "s/\${NETWORK}/${NETWORK}/g" .env

#Update Grafana dashboard with network interface
cp ./config/grafana/dashboards/overview-dashboard.json.template ./config/grafana/dashboards/overview-dashboard.json
sed -i "s/\${NETWORK_INTERFACE}/${DEFAULT_INTERFACE}/g" ./config/grafana/dashboards/overview-dashboard.json

cp ./config/grafana/provisioning/alerting/contact-points.yaml.template ./config/grafana/provisioning/alerting/contact-points.yaml
sed -i "s/\${GF_SMTP_FROM_ADDRESS}/${GF_SMTP_FROM_ADDRESS}/g" ./config/grafana/provisioning/alerting/contact-points.yaml

echo -e "\n.env file generated"
