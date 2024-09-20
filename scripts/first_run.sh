source ./.env

#Install node_exporter
echo -e "\nSetting up node_exporter"
./scripts/install_node_exp.sh
nohup /usr/local/bin/node_exporter > /dev/null 2>&1 & 

#Run first time app scripts
./config/sftpgo/init.sh

echo -e "\nSetup Complete"
read -p "Press Enter to Launch"
./scripts/up.sh
URL="https://grafana.$INTERNAL_DOMAIN:4443/d/edwqapvydmmf4b/overview?orgId=1&from=now-1h&to=now&refresh=5s"
nohup xdg-open "$URL" > /dev/null 2>&1 &