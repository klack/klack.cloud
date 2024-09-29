#!/bin/bash
source ./.env
echo  -e "\nDownloading sample files"
wget -q --show-progress https://download.blender.org/demo/movies/BBB/bbb_sunflower_1080p_30fps_normal.mp4.zip
unzip bbb_sunflower_1080p_30fps_normal.mp4.zip -d $DIR_CLOUD_ROOT/$CLOUD_USER/Library/Movies
rm bbb_sunflower_1080p_30fps_normal.mp4.zip
mv $DIR_CLOUD_ROOT/$CLOUD_USER/Library/Movies/bbb_sunflower_1080p_30fps_normal.mp4 "$DIR_CLOUD_ROOT/$CLOUD_USER/Library/Movies/Big Buck Bunny (2008).mp4"

