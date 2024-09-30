#!/bin/bash

echo -e "\nProvisioning plex"
source ./.env

tar -xzf ./config/plex/provision.tar.gz -C $DIR_DATA_ROOT
cp ./config/plex/Preferences.xml.template "$DIR_DATA_ROOT/plex/Library/Application Support/Plex Media Server/Preferences.xml"
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" "$DIR_DATA_ROOT/plex/Library/Application Support/Plex Media Server/Preferences.xml"
