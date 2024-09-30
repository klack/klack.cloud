#!/bin/bash

echo -e "\nProvisioning sonarr"
source ./.env

BASE_64=$(echo -n "$BASIC_AUTH_USER:$BASIC_AUTH_PASS" | base64)

# Wait for sonarr to be marked as healthy
echo "Waiting for sonarr to be healthy..."
SERVER="https://sonarr.${INTERNAL_DOMAIN}:4443"
CHECK_URL="$SERVER"
TIMEOUT=60       # Maximum time to wait (in seconds)
RETRY_INTERVAL=5 # Time between retries
SECONDS_WAITED=0
until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' $CHECK_URL -H 'Authorization: Basic '"$BASE_64"'' -k)" == "200" ]]; do
    SECONDS_WAITED=$((SECONDS_WAITED + RETRY_INTERVAL))
    if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
        echo "sonarr did not return 200 after $SECONDS_WAITED seconds, exiting."
        exit 1
    fi
    echo "Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done

# Setup qbittorrent as download client
curl 'https://sonarr.'"$INTERNAL_DOMAIN"':4443/api/v3/downloadclient?' \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H 'X-Api-Key: '"$SONARR_API_KEY"'' \
    -H 'Authorization: Basic '"$BASE_64"'' \
    --data-raw '{
        "enable": true,
        "protocol": "torrent",
        "priority": 1,
        "removeCompletedDownloads": true,
        "removeFailedDownloads": true,
        "name": "qBittorrent",
        "fields": [
            {"name": "host", "value": "localhost"},
            {"name": "port", "value": 8080},
            {"name": "useSsl", "value": false},
            {"name": "urlBase"},
            {"name": "username", "value": "'"$BASIC_AUTH_USER"'" },
            {"name": "password", "value": "'"$BASIC_AUTH_PASS"'" },
            {"name": "tvCategory", "value": "tv-sonarr"},
            {"name": "tvImportedCategory"},
            {"name": "recentTvPriority", "value": 0},
            {"name": "olderTvPriority", "value": 0},
            {"name": "initialState", "value": 0},
            {"name": "sequentialOrder", "value": false},
            {"name": "firstAndLast", "value": false},
            {"name": "contentLayout", "value": 0}
        ],
        "implementationName": "qBittorrent",
        "implementation": "QBittorrent",
        "configContract": "QBittorrentSettings",
        "infoLink": "https://wiki.servarr.com/sonarr/supported#qbittorrent",
        "tags": []
    }'

curl 'https://sonarr.'"$INTERNAL_DOMAIN"':4443/api/v3/rootFolder' \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H 'X-Api-Key: '"$SONARR_API_KEY"'' \
    -H 'Authorization: Basic '"$BASE_64"'' \
    --data-raw '{"path":"/data/'"$BASIC_AUTH_USER"'/Library/TV/"}'

echo "sonarr first time run complete"
