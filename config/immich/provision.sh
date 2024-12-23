#!/bin/bash

echo -e "\nProvisioning immich"
source ./.env

SERVER=https://$HOST_IP:2283
USER=$CLOUD_USER@$EXTERNAL_DOMAIN
PASSWORD=$CLOUD_PASS
#Download sample files
echo "Downloading sample files"
mkdir ./tmp
wget -q --show-progress -O ./tmp/starry_night.jpg https://upload.wikimedia.org/wikipedia/commons/c/cd/VanGogh-starry_night.jpg
wget -q --show-progress -O ./tmp/over_the_rhone.jpg https://upload.wikimedia.org/wikipedia/commons/9/94/Starry_Night_Over_the_Rhone.jpg
wget -q --show-progress -O ./tmp/vincent_van_gogh.jpg "https://upload.wikimedia.org/wikipedia/commons/4/4c/Vincent_van_Gogh_-_Self-Portrait_-_Google_Art_Project_%28454045%29.jpg"

# Wait for immich to be marked as healthy
echo "Waiting for immich to be healthy..."
CHECK_URL="$SERVER"
TIMEOUT=500      # Maximum time to wait (in seconds)
RETRY_INTERVAL=5 # Time between retries
SECONDS_WAITED=0
until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' $CHECK_URL -k)" == "200" ]]; do
    SECONDS_WAITED=$((SECONDS_WAITED + RETRY_INTERVAL))
    if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
        echo "immich did not return 200 after $SECONDS_WAITED seconds, exiting."
        exit 1
    fi
    printf "."
    sleep $RETRY_INTERVAL
done

# Create admin
curl $SERVER/api/auth/admin-sign-up -X POST \
    -k \
    -H 'content-type: application/json' \
    --data-raw "{\"email\": \"$USER\", \"password\": \"$PASSWORD\", \"name\":\"$CLOUD_USER\"}"

# Get access token
ACCESS_TOKEN=$(curl -s -L $SERVER/api/auth/login \
    -k \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    --data-raw "{\"email\": \"$USER\", \"password\": \"$PASSWORD\"}" |
    jq -r '.accessToken')

# Upload sample files
FILES=(./tmp/*)
# Loop through each file in the list
for FILE in "${FILES[@]}"; do
    MTIME=$(stat -c %Y "$FILE")
    DEVICE_ASSET_ID="${FILE}-${MTIME}"
    FILE_CREATED_AT=$(date -d @$MTIME --utc +'%Y-%m-%dT%H:%M:%S.%NZ')
    FILE_MODIFIED_AT=$(date -d @$MTIME --utc +'%Y-%m-%dT%H:%M:%S.%NZ')

    # Perform the upload for each file
    echo
    curl -X POST $SERVER/api/assets \
        -k \
        -H "Accept: application/json" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -F "deviceAssetId=$DEVICE_ASSET_ID" \
        -F "deviceId=provision" \
        -F "fileCreatedAt=$FILE_CREATED_AT" \
        -F "fileModifiedAt=$FILE_MODIFIED_AT" \
        -F "isFavorite=false" \
        -F "assetData=@$FILE"
done

#Cleanup
rm -rf ./tmp

echo -e "\nimmich first time run complete"
