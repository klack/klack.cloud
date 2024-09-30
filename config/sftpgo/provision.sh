#!/bin/bash -x

echo -e "\nProvisioning sftpgo"
source ./.env

#Start up sftpgo
docker compose up traefik sftpgo -d

# Wait for SFTPGo to be marked as healthy
echo "Waiting for SFTPGo to be healthy..."
SERVER="https://sftpgo.${INTERNAL_DOMAIN}:4443"
CHECK_URL="$SERVER/web/client/login"
TIMEOUT=60  # Maximum time to wait (in seconds)
RETRY_INTERVAL=5  # Time between retries
SECONDS_WAITED=0
until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' $CHECK_URL -k)" == "200" ]]; do
    SECONDS_WAITED=$((SECONDS_WAITED + RETRY_INTERVAL))
    if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
        echo "SFTPGo did not return 200 after $SECONDS_WAITED seconds, exiting."
        exit 1
    fi
    echo "Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done


#Create default user
echo "Getting token"
SERVER="https://sftpgo.${INTERNAL_DOMAIN}:4443"
BASE_64=$(echo -n "$BASIC_AUTH_USER:$BASIC_AUTH_PASS" | base64)
TOKEN_RESPONSE=$(curl -sS "$SERVER/api/v2/token" -H "Authorization: Basic $BASE_64" -H "Content-Type: application/json" -k)
TOKEN=$(echo $TOKEN_RESPONSE | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
echo "Creating user"
sed "s|\${CLOUD_USER}|${CLOUD_USER}|g; \
     s|\${CLOUD_PASS}|${CLOUD_PASS}|g" \
     ./config/sftpgo/user.json.template > ./config/sftpgo/user.json
curl -X POST "$SERVER/api/v2/users" \
-k \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type: application/json" \
-d @./config/sftpgo/user.json
docker compose down traefik sftpgo

echo "sftpgo first time run complete"