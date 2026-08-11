#!/bin/bash

if [ "$(basename "$PWD")" != "klack.cloud" ]; then
  echo "Must be run from base project directory"
  exit 1
fi

source ./.env

/usr/bin/rclone copy -v "${DIR_BACKUPS}/" koofr:backups/
