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

#Get out of the scripts directory
if [ "$(basename "$(dirname "$PWD")")" = "scripts" ]; then
  cd ..
fi

#Start
echo -e "\nStarting"
docker compose --profile apps up -d

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

#Generate home page
cp ./web/index.html.template ./web/index.html
sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${HOST_IP}/${HOST_IP}/g" ./web/index.html
echo -e "\nIndex.html created"

#Show home page
echo -e "\nklack.cloud launched!"
echo -e "\nFinish setup at http://$HOST_IP"
