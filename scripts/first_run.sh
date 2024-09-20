source ./.env

#Install node_exporter
echo -e "\nSetting up node_exporter"
./scripts/install_node_exp.sh
nohup /usr/local/bin/node_exporter > /dev/null 2>&1 & 

#Run first time app scripts
./config/sftpgo/init.sh

cp ./index.html.template index.html
sed -i "s/\${INTERNAL_DOMAIN}/${INTERNAL_DOMAIN}/g" index.html
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" index.html

echo -e "\nIndex.html created"

#Sample files
echo  -e "\nDownloading sample files"
wget https://download.blender.org/demo/movies/BBB/bbb_sunflower_1080p_30fps_normal.mp4.zip
unzip bbb_sunflower_1080p_30fps_normal.mp4.zip -d ./data/klack.tv/library/movies
rm bbb_sunflower_1080p_30fps_normal.mp4.zip
wget -P ./data/sftpgoroot/data/cloud/Photos https://commons.wikimedia.org/wiki/Vincent_van_Gogh#/media/File:VanGogh-starry_night.jpg
wget -P ./data/sftpgoroot/data/cloud/Photos https://commons.wikimedia.org/wiki/Vincent_van_Gogh#/media/File:Starry_Night_Over_the_Rhone.jpg
wget -P ./data/sftpgoroot/data/cloud/Photos "https://commons.wikimedia.org/wiki/Vincent_van_Gogh#/media/File:Vincent_van_Gogh_-_Self-Portrait_-_Google_Art_Project_(454045).jpg"


echo -e "\nSetup Complete"
read -p "Press Enter to Launch"
./scripts/up.sh
URL=./index.html
nohup xdg-open "$URL" > /dev/null 2>&1 &