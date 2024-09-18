nohup /usr/local/bin/node_exporter > /dev/null 2>&1 & 
echo "node_exporter started"
docker compose up -d
./config/sftpgo/init.sh