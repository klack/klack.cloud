#!/bin/bash

source ./.env

echo -e "\nPlex Setup"

#Download sample movie
source ./.env
echo -e "Downloading sample files"
wget -q --show-progress https://download.blender.org/demo/movies/BBB/bbb_sunflower_1080p_30fps_normal.mp4.zip
unzip bbb_sunflower_1080p_30fps_normal.mp4.zip -d $DIR_CLOUD_ROOT/$CLOUD_USER/Library/Movies
rm bbb_sunflower_1080p_30fps_normal.mp4.zip
mv $DIR_CLOUD_ROOT/$CLOUD_USER/Library/Movies/bbb_sunflower_1080p_30fps_normal.mp4 "$DIR_CLOUD_ROOT/$CLOUD_USER/Library/Movies/Big Buck Bunny (2008).mp4"

#Ask for claim token
echo
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
    sed -i "s/\${CLOUD_USER}/${CLOUD_USER}/g" "$DIR_DATA_ROOT/plex/Library/Application Support/Plex Media Server/Preferences.xml"
    
    echo -e "\nPlex Setup complete"
fi
