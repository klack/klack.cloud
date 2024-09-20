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

echo -e "\nSetup Complete"
read -p "Press Enter to Launch"
./scripts/up.sh
URL=./index.html
nohup xdg-open "$URL" > /dev/null 2>&1 &