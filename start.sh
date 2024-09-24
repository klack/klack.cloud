#!/bin/bash

if [ ! -f "./.env" ]; then
  echo "Run ./setup.sh first"
fi

source ./.env

if [ "$(basename "$(dirname "$PWD")")" = "scripts" ]; then
  cd ..
fi

#Generate home page
cp ./web/index.html.template ./web/index.html
sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${HOST_IP}/${HOST_IP}/g" ./web/index.html

# Check if ./config/wg0.conf exists
if [ -f "./config/wireguard/wg0.conf" ]; then
  # If wg0.conf exists, run docker compose with profile apps and downloaders
  sed -i '/#download_managers {/{N;s/display: block;/display: none;/}' ./web/index.html
  docker compose --profile apps --profile downloaders up -d
else
  # If wg0.conf does not exist, run docker compose without the profiles
  docker compose --profile apps up -d
  
fi

echo -e "\nIndex.html created"

#Show home page
echo -e "\nklack.cloud launched!"
echo -e "\nVisit your homepage at http://$HOST_IP"