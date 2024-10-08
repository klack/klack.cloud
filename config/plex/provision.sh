#!/bin/bash

source ./.env

echo -e "\nPlex Setup"
read -p "Visit https://plex.tv/claim and paste claim token, or press enter to skip: " PLEX_CLAIM

if [ -z "$PLEX_CLAIM" ]; then
    #Disable plex in .env
    echo "Skipping Plex setup"
else
    #Set the claim token
    sed -i "s|^PLEX_CLAIM=.*|PLEX_CLAIM=$PLEX_CLAIM|" .env
    #Provision default settings
    tar -xzf ./config/plex/provision.tar.gz -C $DIR_DATA_ROOT
    cp ./config/plex/Preferences.xml.template "$DIR_DATA_ROOT/plex/Library/Application Support/Plex Media Server/Preferences.xml"
    sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" "$DIR_DATA_ROOT/plex/Library/Application Support/Plex Media Server/Preferences.xml"
fi

echo -e "\nPlex Setup complete"

