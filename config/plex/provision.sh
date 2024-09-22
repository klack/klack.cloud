#!/bin/bash
echo -e "\nProvisioning plex"
source ./.env

tar -xzvf ./config/plex/provision.tar.gz -C $DIR_DATA_ROOT