#!/bin/bash

echo -e "\nProvisioning sftpgo"
source ./.env

#Start up sftpgo
# docker compose up traefik sftpgo -d

# Wait for SFTPGo to be marked as healthy
echo "Waiting for SFTPGo to be healthy..."
SERVER="https://$HOST_IP:8081"
CHECK_URL="$SERVER/web/client/login"
TIMEOUT=500  # Maximum time to wait (in seconds)
RETRY_INTERVAL=5 # Time between retries
SECONDS_WAITED=0
until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' $CHECK_URL -k)" == "200" ]]; do
    SECONDS_WAITED=$((SECONDS_WAITED + RETRY_INTERVAL))
    if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
        echo "SFTPGo did not return 200 after $SECONDS_WAITED seconds, exiting."
        exit 1
    fi
    printf "."
    sleep $RETRY_INTERVAL
done

#Create default user
echo "Getting token"
TOKEN_RESPONSE=$(curl -sS "$SERVER/api/v2/token" -H "Authorization: Basic $BASIC_AUTH_BASE64" -H "Content-Type: application/json" -k)
TOKEN=$(echo $TOKEN_RESPONSE | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
echo "Creating user"
sed "s|\${CLOUD_USER}|${CLOUD_USER}|g; \
     s|\${CLOUD_PASS}|${CLOUD_PASS}|g" \
    ./config/sftpgo/user.json.template >./config/sftpgo/user.json
curl -X POST "$SERVER/api/v2/users" \
    -k \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d @./config/sftpgo/user.json
# docker compose down traefik sftpgo

echo "sftpgo first time run complete"
