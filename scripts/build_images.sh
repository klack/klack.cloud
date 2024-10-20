#!/bin/bash

source ./.env

#Build docker images
if [ $PLATFORM == "linux/arm64" ]; then
    echo -e "\nBuilding Plex"
    docker build --platform linux/arm64 --pull --no-cache -t plexinc/pms-docker ./config/plex/git
    echo -e "\nBuilding Dionaea"
    docker build --platform linux/arm64 --pull --no-cache -t dinotools/dionaea ./config/dionaea/git
fi