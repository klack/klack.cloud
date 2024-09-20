#Install node_exporter
echo "Installing node_exporter"
./scripts/install_node_exp.sh
echo "Starting node_exporter"
nohup /usr/local/bin/node_exporter > /dev/null 2>&1 & 

#Run first time app scripts
docker compose up -d
./config/sftpgo/init.sh

./scripts/up.sh
echo -e "\nSetup Complete"