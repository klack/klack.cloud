#!/bin/bash

# Get the architecture
ARCH=$(uname -m)

# Map architectures to platform strings
case "$ARCH" in
x86_64)
  PLATFORM="linux/amd64"
  ;;
aarch64)
  PLATFORM="linux/arm64"
  ;;
*)
  echo "Unsupported architecture: $ARCH"
  exit 1
  ;;
esac

#Disable Downloaders if vpn.conf is not present
if [ ! -e "./vpn.conf" ]; then
  echo "vpn.conf is not present.  Downloaders will not be setup."
  ENABLE_DOWNLOADERS=0
  sed -i "s|^ENABLE_DOWNLOADERS=.*|ENABLE_DOWNLOADERS=\"$ENABLE_DOWNLOADERS\"|" .env
fi

#Password Prompting
read -p "Enter your domain name: " EXTERNAL_DOMAIN
read -p "Create a username: " USERNAME
read -s -p "Create a password: " PASSWORD
echo
read -s -p "Enter password again: " PASSWORD_CONFIRM
echo
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
  echo "Passwords do not match. Exiting."
  exit 1
fi

#.env file generation
cp -p ./.env.template ./.env

#Platform
sed -i "s|^PLATFORM=.*|PLATFORM=\"$PLATFORM\"|" .env

TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
sed -i "s|^TZ=.*|TZ=$TIMEZONE|" .env

#External Domain
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" .env

#Passwords
ESCAPED_PASSWORD=$(printf '%s\n' "$PASSWORD" | sed 's/\([\"$]\)/\\\1/g')
ESCAPED_CLOUD_PASSWORD=$(printf '%s\n' "$CLOUD_PASSWORD" | sed 's/\([\"$]\)/\\\1/g')
BASIC_AUTH_BASE64=$(echo -n "$USERNAME:$PASSWORD" | base64)
sed -i "s|^BASIC_AUTH_USER=.*|BASIC_AUTH_USER=\"$USERNAME\"|" .env
sed -i "s|^BASIC_AUTH_PASS=.*|BASIC_AUTH_PASS=\"$ESCAPED_PASSWORD\"|" .env
sed -i "s|^CLOUD_USER=.*|CLOUD_USER=\"$USERNAME\"|" .env
sed -i "s|^CLOUD_PASS=.*|CLOUD_PASS=\"$ESCAPED_PASSWORD\"|" .env
sed -i "s|^BASIC_AUTH_BASE64=.*|BASIC_AUTH_BASE64=\"$BASIC_AUTH_BASE64\"|" .env

#Generate htpassword
docker run --rm httpd:latest htpasswd \
  -Bbn $USERNAME "$PASSWORD" > \
  ./config/traefik/htpasswd && echo "htpassword generated"

#Photoprism
MARIADB_PASSWORD=$(tr </dev/urandom -dc 'A-Za-z0-9!@#%' | head -c 16)
MARIADB_ROOT_PASSWORD=$(tr </dev/urandom -dc 'A-Za-z0-9!@#%' | head -c 16)
sed -i "s|^MARIADB_ROOT_PASSWORD=.*|MARIADB_ROOT_PASSWORD=\"$MARIADB_ROOT_PASSWORD\"|" .env
sed -i "s|^MARIADB_PASSWORD=.*|MARIADB_PASSWORD=\"$MARIADB_PASSWORD\"|" .env

#Sonarr / Radarr
SONARR_API_KEY=$(openssl rand -hex 16)
RADARR_API_KEY=$(openssl rand -hex 16)
JACKETT_API_KEY=$(openssl rand -hex 16)
JACKETT_INSTANCE_ID=$(openssl rand -hex 32)

sed -i "s|^SONARR_API_KEY=.*|SONARR_API_KEY=\"$SONARR_API_KEY\"|" .env
sed -i "s|^RADARR_API_KEY=.*|RADARR_API_KEY=\"$RADARR_API_KEY\"|" .env
sed -i "s|^JACKETT_API_KEY=.*|JACKETT_API_KEY=\"$JACKETT_API_KEY\"|" .env

cp -p ./config/radarr/config.xml.template ./config/radarr/config.xml
sed -i "s/\${API_KEY}/${RADARR_API_KEY}/g" ./config/radarr/config.xml

cp ./config/sonarr/config.xml.template ./config/sonarr/config.xml
sed -i "s/\${API_KEY}/${SONARR_API_KEY}/g" ./config/sonarr/config.xml

cp ./config/jackett/ServerConfig.json.template ./config/jackett/ServerConfig.json
sed -i "s/\${API_KEY}/${JACKETT_API_KEY}/g" ./config/jackett/ServerConfig.json
sed -i "s/\${INSTANCE_ID}/${JACKETT_INSTANCE_ID}/g" ./config/jackett/ServerConfig.json

#Set qBittorrent password
cp -p ./config/qbittorrent/qBittorrent.conf.template ./config/qbittorrent/qBittorrent.conf
PASSWORD_PBKDF2="$(docker run --rm -v ./scripts:/app -w /app python:3.10-slim python generate_pkbdf2.py "$PASSWORD")"
sed -i "s#\${PASSWORD_PBKDF2}#${PASSWORD_PBKDF2}#g" ./config/qbittorrent/qBittorrent.conf
sed -i "s#\${USERNAME}#${USERNAME}#g" ./config/qbittorrent/qBittorrent.conf

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

#Notifications
echo -e "\nEmail Notifications"
DEFAULT_MAIL_HOST=smtp.protonmail.ch
DEFAULT_MAIL_PORT=587
DEFAULT_MAIL_FROM=notify@$EXTERNAL_DOMAIN
DEFAULT_MAIL_USER=notify@$EXTERNAL_DOMAIN
read -p "Enter your ISP mail server address, or press enter for Proton Mail [$DEFAULT_MAIL_HOST]: " GF_SMTP_HOST
read -p "Enter your ISP mail server port, or press enter for Proton Mail [$DEFAULT_MAIL_PORT]: " GF_SMTP_PORT
read -p "Enter your from address [$DEFAULT_MAIL_FROM]: " GF_SMTP_FROM_ADDRESS
read -p "Enter your SMTP user [notify@$EXTERNAL_DOMAIN]: " GF_SMTP_USER
read -s -p "Enter your SMTP password: " GF_SMTP_PASSWORD
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
echo -e "\n\nHoneypot Setup"
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

echo -e "\n.env file generated"
