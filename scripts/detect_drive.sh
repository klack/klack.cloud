#!/bin/bash

# Search for the NTFS drive with the label "cloud" in /proc/mounts
#Set PWD
MOUNT_PATH=$(grep -i "cloud" /proc/mounts | grep "ntfs" | awk '{print $2}')
if [ -n "$MOUNT_PATH" ]; then
  echo -e "External drive detected at $MOUNT_PATH\n"
  PATH_ROOT=$MOUNT_PATH
else
  echo -e "External drive not detected\n"
  PATH_ROOT=$(pwd)
fi
sed -i "s|\${PATH_ROOT}|${PATH_ROOT}|g" .env
