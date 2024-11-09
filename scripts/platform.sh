#!/bin/bash

source ./.env

#Platform Specific
PWD=$(pwd)
if [ $PLATFORM == "linux/arm64" ]; then
    #Manual update script for plex and dionea
    if ! grep -q "build_images.sh" /etc/crontab; then
        sudo sh -c "sudo echo -e \"0 4 * * * $LOCAL_USER cd $PWD && $PWD/scripts/build_images.sh && $PWD/start.sh\" >> /etc/crontab"
        echo "build_images.sh added to crontab"
    else
        echo "build_images.sh already added to crontab"
    fi

    #Build Images
    ./scripts/build_images.sh
fi
