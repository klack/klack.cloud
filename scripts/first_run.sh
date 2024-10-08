#!/bin/bash

source ./.env

#Run first time app scripts
./config/sftpgo/provision.sh
./config/jackett/provision.sh
./config/radarr/provision.sh
./config/sonarr/provision.sh
./config/immich/provision.sh

echo -e "\nFirst time setup complete"
