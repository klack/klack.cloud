#!/bin/bash

if [ "$EUID" == 0 ]; then
  echo "Do not initiate this script as root"
  exit 1
fi

#Optionally run clean script
if [[ "$1" == "--clean" ]]; then
  sudo ./scripts/clean.sh
  exit 0
fi

#Generate Config
sudo ./scripts/gen_config.sh
if [ $? -ne 0 ]; then
  echo ".env generation failed"
  exit 1
fi

source ./.env

#Shut down everything
echo "Shutting down services"
./scripts/down.sh
sudo killall node_exporter
docker volume rm klack-cloud-photoprism-db-1 #Remove so maria database can be reprovisioned
rm -v ./config/sftpgo/homeuser/sftpgo.db #Remove so user can be reprovisioned

#Run first time scripts
sudo ./scripts/first_run.sh
if [ $? -ne 0 ]; then
  echo "First run setup failed"
  exit 1
fi

echo -e "\nSetup Complete"
read -p "Press Enter to Launch"

#Start all docker containers
./start.sh
