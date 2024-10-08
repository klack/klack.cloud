#!/bin/bash

source ./.env

#Run first time app scripts
./config/sftpgo/provision.sh
./config/immich/provision.sh

if [ "$ENABLE_DOWNLOADERS" = "1" ]; then
./config/jackett/provision.sh
./config/radarr/provision.sh
./config/sonarr/provision.sh
fi

./config/plex/provision.sh

echo -e "\nFirst time run setup complete"
