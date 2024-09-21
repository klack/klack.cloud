#!/bin/bash
source ./.env
echo  -e "\nDownloading sample files"
wget https://download.blender.org/demo/movies/BBB/bbb_sunflower_1080p_30fps_normal.mp4.zip
unzip bbb_sunflower_1080p_30fps_normal.mp4.zip -d $DIR_CLOUD_ROOT/$CLOUD_USER/Library/Movies
rm bbb_sunflower_1080p_30fps_normal.mp4.zip
wget -O $DIR_CLOUD_ROOT/$CLOUD_USER/Photos/starry_night.jpg https://upload.wikimedia.org/wikipedia/commons/c/cd/VanGogh-starry_night.jpg
wget -O $DIR_CLOUD_ROOT/$CLOUD_USER/Photos/over_the_rhone.jpg https://upload.wikimedia.org/wikipedia/commons/9/94/Starry_Night_Over_the_Rhone.jpg
wget -O $DIR_CLOUD_ROOT/$CLOUD_USER/Photos/vincent_van_gogh.jpg "https://upload.wikimedia.org/wikipedia/commons/4/4c/Vincent_van_Gogh_-_Self-Portrait_-_Google_Art_Project_%28454045%29.jpg"
