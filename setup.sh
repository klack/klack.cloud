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

export COMPOSE_PROGRESS=plain

# Generate Config
LOCAL_USER=$(whoami) 
sudo LOCAL_USER=$LOCAL_USER ./scripts/gen_config.sh
if [ $? -ne 0 ]; then
  echo ".env generation failed"
  exit 1
fi

# Shut down everything
echo "Shutting down services"
./stop.sh
sudo killall node_exporter

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
