#!/bin/bash

echo -e "\nProvisioning immich"
source ./.env

SERVER=http://localhost:2284
USER=$CLOUD_USER@$EXTERNAL_DOMAIN
PASSWORD=$CLOUD_PASS

#Start up immich
docker compose down immich-server
docker compose -f ./compose.yml -f ./compose/immich.provision.yml up immich-server -d

#Download sample files
mkdir ./tmp
wget -q --show-progress -O ./tmp/starry_night.jpg https://upload.wikimedia.org/wikipedia/commons/c/cd/VanGogh-starry_night.jpg
wget -q --show-progress -O ./tmp/over_the_rhone.jpg https://upload.wikimedia.org/wikipedia/commons/9/94/Starry_Night_Over_the_Rhone.jpg
wget -q --show-progress -O ./tmp/vincent_van_gogh.jpg "https://upload.wikimedia.org/wikipedia/commons/4/4c/Vincent_van_Gogh_-_Self-Portrait_-_Google_Art_Project_%28454045%29.jpg"

# Wait for immich to be marked as healthy
echo "Waiting for immich to be healthy..."
CHECK_URL="$SERVER"
TIMEOUT=120  # Maximum time to wait (in seconds)
RETRY_INTERVAL=5  # Time between retries
SECONDS_WAITED=0
until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' $CHECK_URL -k)" == "200" ]]; do
    SECONDS_WAITED=$((SECONDS_WAITED + RETRY_INTERVAL))
    if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
        echo "immich did not return 200 after $SECONDS_WAITED seconds, exiting."
        exit 1
    fi
    echo "Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done

# Create admin
curl $SERVER/api/auth/admin-sign-up -X POST \
    -H 'content-type: application/json' \
    --data-raw "{\"email\": \"$USER\", \"password\": \"$PASSWORD\", \"name\":\"$CLOUD_USER\"}"

# Get access token
ACCESS_TOKEN=$(curl -s -L $SERVER/api/auth/login \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    --data-raw "{\"email\": \"$USER\", \"password\": \"$PASSWORD\"}" \
    | jq -r '.accessToken')

# Upload sample files
FILES=(./tmp/*)
# Loop through each file in the list
for FILE in "${FILES[@]}"; do
  MTIME=$(stat -c %Y "$FILE")
  DEVICE_ASSET_ID="${FILE}-${MTIME}"
  FILE_CREATED_AT=$(date -d @$MTIME --utc +'%Y-%m-%dT%H:%M:%S.%NZ')
  FILE_MODIFIED_AT=$(date -d @$MTIME --utc +'%Y-%m-%dT%H:%M:%S.%NZ')

  # Perform the upload for each file
  curl -X POST $SERVER/api/assets \
      -H "Accept: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -F "deviceAssetId=$DEVICE_ASSET_ID" \
      -F "deviceId=provision" \
      -F "fileCreatedAt=$FILE_CREATED_AT" \
      -F "fileModifiedAt=$FILE_MODIFIED_AT" \
      -F "isFavorite=false" \
      -F "assetData=@$FILE"

  echo "Uploaded $FILE"
done

#Cleanup
rm -rf ./tmp

echo "immich first time run complete"