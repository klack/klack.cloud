#!/bin/bash -x
cp ./.env.example ./.env
sudo mkdir -vp \
  /var/log/traefik \
  /var/log/duplicati \
  /var/log/dionaea \
  /var/log/cowrie \
  "/var/log/plex/PMS Plugin Logs" \
  /var/log/radarr \
  /var/log/sonarr
sudo chown -vR \
  1000:1000 \
  /var/log/traefik \
  /var/log/duplicati \
  /var/log/dionaea \
  /var/log/plex \
  /var/log/radarr \
  /var/log/sonarr
sudo chown -vR 999:999 /var/log/cowrie
sudo cp ./config/logrotate.d/* /etc/logrotate.d
sudo cp -v ./config/docker/daemon.json /etc/docker/daemon.json
sudo sh -c "cat ./config/hosts/hosts >> /etc/hosts"
read -p "Enter username: " USERNAME
read -s -p "Enter password (no special characters): " PASSWORD
echo
docker run --rm httpd:latest htpasswd \
  -Bbn "$USERNAME" "$PASSWORD" > \
  ./config/traefik/htpasswd
