#!/bin/bash

if [ "$EUID" == 0 ]; then
  echo "Do not initiate this script as root"
  exit 1
fi

# Optionally run clean script
if [[ "$1" == "--clean" ]]; then
  sudo ./scripts/clean.sh
  exit 0
fi

# Generate Config
sudo ./scripts/gen_config.sh
if [ $? -ne 0 ]; then
  echo ".env generation failed"
  exit 1
fi

# Shut down everything
echo "Shutting down services"
./stop.sh
sudo killall node_exporter
docker volume rm klack-cloud-photoprism-db-1 klack-cloud-sftpgo-1 # Remove so MariaDB can be reprovisioned

# Run pre-run scripts
sudo ./scripts/pre_run.sh
if [ $? -ne 0 ]; then
  echo "Pre-run setup failed"
  exit 1
fi

# Start
IN_SETUP=1 ./start.sh

# Run first-time scripts
sudo ./scripts/post_run.sh
if [ $? -ne 0 ]; then
  echo "First run setup failed"
  exit 1
fi

# Start docker containers
./start.sh
