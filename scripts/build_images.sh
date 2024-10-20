#!/bin/bash

source ./.env

#Build docker images
if [ $PLATFORM == "linux/arm64" ]; then
    echo -e "Building Plex"
    docker build --platform linux/arm64 --pull --no-cache -t plexinc/pms-docker ./config/plex/git
    echo -e "Building Dionaea"
    docker build --platform linux/arm64 --pull --no-cache -t dinotools/dionaea ./config/dionaea/git
fi
