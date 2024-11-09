#!/bin/bash

if [ "$EUID" == 0 ]; then
  echo "Do not run as root"
  exit 1
fi

if [ ! -f "./.env" ]; then
  echo "Run ./setup.sh first"
  exit 1
fi

source ./.env

# Honeypot Setup
NETWORK=$(echo "$DEFAULT_GATEWAY" | cut -d '.' -f 1-3)
sed -i "s|^HOST_IP=.*|HOST_IP=$DEFAULT_HOST_IP|" .env
sed -i "s|^HONEYPOT_GATEWAY=.*|HONEYPOT_GATEWAY=$DEFAULT_GATEWAY|" .env
sed -i "s|^NETWORK_INTERFACE=.*|NETWORK_INTERFACE=$DEFAULT_INTERFACE|" .env
sed -i "s/\${NETWORK}/${NETWORK}/g" .env
DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
DEFAULT_HOST_IP=$(hostname -I | awk '{print $1}')
DEFAULT_GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n 1)

#Get out of the scripts directory
if [ "$(basename "$(dirname "$PWD")")" = "scripts" ]; then
  cd ..
fi

#Start
echo -e "\nStarting"
docker compose --profile apps up -d

#Generate home page
cp ./web/index.html.template ./web/index.html

# Check if plex claim token was set
if [ -n "$PLEX_CLAIM" ]; then
  docker compose up plex -d
else
  sed -i '/#video {/{N;s/display: block;/display: none;/}' ./web/index.html # Disable panel on homepage
fi

# Check if ./vpn.conf exists to run download managers
if [ "$ENABLE_DOWNLOADERS" = "1" ]; then
  docker compose --profile downloaders up -d
else
  sed -i '/#download_managers {/{N;s/display: block;/display: none;/}' ./web/index.html # Disable panel on homepage
fi

sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${HOST_IP}/${HOST_IP}/g" ./web/index.html
echo -e "\nIndex.html created"

if [ "$IN_SETUP" != "1" ]; then
  # Show home page
  echo -e "\nklack.cloud launched!"
  echo -e "\nVisit your homepage at https://${HOST_IP}"
fi
