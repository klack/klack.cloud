#!/bin/bash

source ./.env

#First time run scripts
./config/sftpgo/provision.sh

if [ "$ENABLE_DOWNLOADERS" = "1" ]; then
./config/jackett/provision.sh
./config/radarr/provision.sh
./config/sonarr/provision.sh
fi

./config/immich/provision.sh
./config/plex/provision.sh

echo -e "\nPost-run setup complete"
