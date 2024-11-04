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
PWD=$(pwd)
DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}')
DEFAULT_HOST_IP=$(hostname -I | awk '{print $1}')
DEFAULT_GATEWAY=$(ip route | grep default | awk '{print $3}')

# Setup start messages
clear
echo -e "---klack.cloud Setup ($DEFAULT_HOST_IP)---\n"

#.env file generation
cp -p ./.env.template ./.env

#Set PWD
sed -i "s|\${PWD}|${PWD}|g" .env

# Disable Downloaders if vpn.conf is not present
if [ ! -e "./vpn.conf" ]; then
  echo -e "vpn.conf is not present. \nDownloaders will not be setup.\n"
  ENABLE_DOWNLOADERS=0
  sed -i "s|^ENABLE_DOWNLOADERS=.*|ENABLE_DOWNLOADERS=\"$ENABLE_DOWNLOADERS\"|" .env
fi

# Password Prompting
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

# Local user
sed -i "s|^LOCAL_USER=.*|LOCAL_USER=\"$LOCAL_USER\"|" .env

# Platform
sed -i "s|^PLATFORM=.*|PLATFORM=\"$PLATFORM\"|" .env

# Set Timezone
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
sed -i "s|^TZ=.*|TZ=$TIMEZONE|" .env

# External Domain
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" .env

# Passwords
ESCAPED_PASSWORD=$(printf '%s\n' "$PASSWORD" | sed 's/\(["$]\)/\\\1/g')
BASIC_AUTH_BASE64=$(echo -n "$USERNAME:$PASSWORD" | base64)
sed -i "s|^CLOUD_USER=.*|CLOUD_USER=\"$USERNAME\"|" .env
sed -i "s|^CLOUD_PASS=.*|CLOUD_PASS=\"$ESCAPED_PASSWORD\"|" .env
sed -i "s|^BASIC_AUTH_BASE64=.*|BASIC_AUTH_BASE64=\"$BASIC_AUTH_BASE64\"|" .env

# Generate htpassword
docker run --rm httpd:latest htpasswd \
  -Bbn $USERNAME "$PASSWORD" > \
  ./config/traefik/htpasswd && echo "htpassword generated"

# Immich Setup
IMMICH_DB_PASSWORD=$(tr </dev/urandom -dc 'A-Za-z0-9!@#%' | head -c 16)
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=\"$IMMICH_DB_PASSWORD\"|" .env

#Set Servarr api keys
RADARR_API_KEY=$(head -c 16 /dev/urandom | xxd -p)
cp -p ./config/radarr/config.xml.template ./config/radarr/config.xml
sed -i "s/\${API_KEY}/${RADARR_API_KEY}/g" ./config/radarr/config.xml
sed -i "s|^RADARR_API_KEY=.*|RADARR_API_KEY=\"$RADARR_API_KEY\"|" .env

SONARR_API_KEY=$(head -c 16 /dev/urandom | xxd -p)
cp ./config/sonarr/config.xml.template ./config/sonarr/config.xml
sed -i "s/\${API_KEY}/${SONARR_API_KEY}/g" ./config/sonarr/config.xml
sed -i "s|^SONARR_API_KEY=.*|SONARR_API_KEY=\"$SONARR_API_KEY\"|" .env

JACKETT_API_KEY=$(openssl rand -hex 16)
JACKETT_INSTANCE_ID=$(openssl rand -hex 32)
cp ./config/jackett/ServerConfig.json.template ./config/jackett/ServerConfig.json
sed -i "s/\${API_KEY}/${JACKETT_API_KEY}/g" ./config/jackett/ServerConfig.json
sed -i "s/\${INSTANCE_ID}/${JACKETT_INSTANCE_ID}/g" ./config/jackett/ServerConfig.json
sed -i "s|^JACKETT_API_KEY=.*|JACKETT_API_KEY=\"$JACKETT_API_KEY\"|" .env

#Set qBittorrent password
cp -p ./config/qbittorrent/qBittorrent.conf.template ./config/qbittorrent/qBittorrent.conf
PASSWORD_PBKDF2="$(docker run --rm -v ./scripts:/app -w /app python:3.10-slim python generate_pkbdf2.py "$PASSWORD")"
sed -i "s#\${PASSWORD_PBKDF2}#${PASSWORD_PBKDF2}#g" ./config/qbittorrent/qBittorrent.conf
sed -i "s#\${USERNAME}#${USERNAME}#g" ./config/qbittorrent/qBittorrent.conf

# Honeypot Setup
NETWORK=$(echo "$DEFAULT_GATEWAY" | cut -d '.' -f 1-3)
sed -i "s|^HOST_IP=.*|HOST_IP=$DEFAULT_HOST_IP|" .env
sed -i "s|^HONEYPOT_GATEWAY=.*|HONEYPOT_GATEWAY=$DEFAULT_GATEWAY|" .env
sed -i "s|^NETWORK_INTERFACE=.*|NETWORK_INTERFACE=$DEFAULT_INTERFACE|" .env
sed -i "s/\${NETWORK}/${NETWORK}/g" .env

# Email Notifications Setup
DEFAULT_MAIL_HOST=smtp.protonmail.ch
DEFAULT_MAIL_PORT=587
DEFAULT_MAIL_FROM=notify@$EXTERNAL_DOMAIN
DEFAULT_MAIL_USER=notify@$EXTERNAL_DOMAIN
sed -i "s|^GF_SMTP_FROM_ADDRESS=.*|GF_SMTP_FROM_ADDRESS=$DEFAULT_MAIL_FROM|" .env
sed -i "s|^GF_SMTP_USER=.*|GF_SMTP_USER=$DEFAULT_MAIL_USER|" .env
sed -i "s/\${GF_SMTP_HOST}/${DEFAULT_MAIL_HOST}/g" .env
sed -i "s/\${GF_SMTP_PORT}/${DEFAULT_MAIL_HOST}/g" .env

echo -e "\n.env file generated"
