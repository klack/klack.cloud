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

if [ "$(basename "$(dirname "$PWD")")" = "scripts" ]; then
  cd ..
fi

#Generate home page
cp ./web/index.html.template ./web/index.html
sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" ./web/index.html
sed -i "s/\${HOST_IP}/${HOST_IP}/g" ./web/index.html

docker compose --profile apps up -d
# Check if ./config/wg0.conf exists to run download managers
if [ -f "./config/wireguard/wg0.conf" ]; then
  docker compose --profile downloaders up -d
else
  sed -i '/#download_managers {/{N;s/display: block;/display: none;/}' ./web/index.html # Disable panel on homepage
fi

# Check if plex claim token was set
if [ -n "$PLEX_CLAIM" ]; then
  docker compose up plex -d
else
  sed -i '/#video {/{N;s/display: block;/display: none;/}' ./web/index.html # Disable panel on homepage
fi

echo -e "\nIndex.html created"

echo "Starting..."
SERVER="http://traefik.${INTERNAL_DOMAIN}"
CHECK_URL="$SERVER/"
TIMEOUT=60  # Maximum time to wait (in seconds)
RETRY_INTERVAL=5  # Time between retries
SECONDS_WAITED=0
until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' $CHECK_URL)" == "200" ]]; do
    SECONDS_WAITED=$((SECONDS_WAITED + RETRY_INTERVAL))
    if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
        echo "Service not reachable start after $SECONDS_WAITED seconds, exiting."
        exit 1
    fi
    echo "."
    sleep $RETRY_INTERVAL
done

#Show home page
echo -e "\nklack.cloud launched!"
echo -e "\nFinish setup at http://$HOST_IP"
