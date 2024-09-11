#!/bin/bash
./down.sh

if [[ "$1" == "--clean" ]]; then
  echo "Deleting docker volumes"
  docker volume ls -q | grep '^klack-cloud_' | xargs -r docker volume rm -f
fi

cp ./.env.template ./.env

#Setup logs folders and perms
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

#Copy docker daemon
if [ ! -f /etc/docker/daemon.json ]; then
    sudo cp -v ./config/docker/daemon.json /etc/docker/daemon.json
fi

#Edit hosts file
if ! grep -q ".klack.internal" /etc/hosts; then
    sudo sh -c "cat ./config/hosts/hosts >> /etc/hosts"
fi

#Prompt for info
DEFAULT_HOST_IP=$(hostname -I | awk '{print $1}')
DEFUALT_GATEWAY=$(ip route | grep default | awk '{print $3}')
DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}')
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
read -p "Enter external domain: " EXTERNAL_DOMAIN
read -s -p "Enter password: " PASSWORD
echo
read -s -p "Enter password again: " PASSWORD_CONFIRM
echo
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "Passwords do not match. Exiting."
    exit 1  # Exit the script with a non-zero status
fi
read -p "Visit https://plex.tv/claim and paste claim token: " PLEX_CLAIM
read -p "Press enter for default network interface [$DEFAULT_INTERFACE]: " HOST_IP
read -p "Press enter for default host IP [$DEFAULT_HOST_IP]: " HOST_IP
read -p "Press enter for default gateway [$DEFUALT_GATEWAY]: " GATEWAY
HOST_IP=${HOST_IP:-"$DEFAULT_HOST_IP"}
GATEWAY=${GATEWAY:-"$DEFUALT_GATEWAY"}
NETWORK=$(echo "$GATEWAY" | cut -d '.' -f 1-3)
ESCAPED_PASSWORD=$(printf '%s\n' "$PASSWORD" | sed 's/\([\"$]\)/\\\1/g')
MARIADB_PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#%^&*()-_=+' | head -c 16)
MARIADB_ROOT_PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#%^&*()-_=+' | head -c 16)

#Update .env file
sed -i "s|^TZ=.*|TZ=\"$TIMEZONE\"|" .env
sed -i "s|^EXTERNAL_DOMAIN=.*|EXTERNAL_DOMAIN=$EXTERNAL_DOMAIN|" .env
sed -i "s|^PLEX_CLAIM=.*|PLEX_CLAIM=$PLEX_CLAIM|" .env
sed -i "s|^NODE_EXPORTER_PASS=.*|NODE_EXPORTER_PASS=\"$ESCAPED_PASSWORD\"|" .env
sed -i "s|^PHOTOPRISM_ADMIN_PASSWORD=.*|PHOTOPRISM_ADMIN_PASSWORD=\"$ESCAPED_PASSWORD\"|" .env
sed -i "s|^MARIADB_PASSWORD=.*|MARIADB_PASSWORD=\"$MARIADB_PASSWORD\"|" .env
sed -i "s|^MARIADB_ROOT_PASSWORD=.*|MARIADB_ROOT_PASSWORD=\"$MARIADB_ROOT_PASSWORD\"|" .env
sed -i "s|^HOST_IP=.*|HOST_IP=$HOST_IP|" .env
sed -i "s|^HONEYPOT_GATEWAY=.*|HONEYPOT_GATEWAY=$GATEWAY|" .env
sed -i "s|^NETWORK_INTERFACE=.*|NETWORK_INTERFACE=$DEFAULT_INTERFACE|" .env
sed -i "s/\${NETWORK}/${NETWORK}/g" .env
sed -i "s/\${EXTERNAL_DOMAIN}/${EXTERNAL_DOMAIN}/g" .env

#Generate htpassword
docker run --rm httpd:latest htpasswd \
  -Bbn admin "$PASSWORD" > \
  ./config/traefik/htpasswd

echo ".env generated"