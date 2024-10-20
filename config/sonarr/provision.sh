#!/bin/bash

echo -e "\nProvisioning sonarr"
source ./.env

# Wait for sonarr to be marked as healthy
echo "Waiting for sonarr to be healthy..."
SERVER="https://sonarr.${INTERNAL_DOMAIN}:4443"
CHECK_URL="$SERVER"
TIMEOUT=500      # Maximum time to wait (in seconds)
RETRY_INTERVAL=5 # Time between retries
SECONDS_WAITED=0
until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' $CHECK_URL -H "Authorization: Basic $BASIC_AUTH_BASE64" -k)" == "200" ]]; do
    SECONDS_WAITED=$((SECONDS_WAITED + RETRY_INTERVAL))
    if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
        echo "sonarr did not return 200 after $SECONDS_WAITED seconds, exiting."
        exit 1
    fi
    printf "."
    sleep $RETRY_INTERVAL
done

# Setup Library Path
echo "Setting TV path"
curl "$SERVER/api/v3/rootFolder" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $SONARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"path":"/data/Library/TV/"}' \
    -s -o /dev/null -w '%{http_code}\n'

# Setup qbittorrent as download client
echo "Adding qBittorrent as a download client"
curl "$SERVER/api/v3/downloadclient?" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $SONARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
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
    }' \
    -s -o /dev/null -w '%{http_code}\n'

# Add 1337x
echo "Adding 1337x"
curl "$SERVER/api/v3/indexer?" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $SONARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"torrent","priority":25,"seasonSearchMaximumSingleEpisodeAge":0,"downloadClientId":0,"name":"1337x","fields":[{"name":"baseUrl","value":"http://localhost:9117/api/v2.0/indexers/1337x/results/torznab/"},{"name":"apiPath","value":"/api"},{"name":"apiKey","value":"'$JACKETT_API_KEY'"},{"name":"categories","value":[5030,5040,5080,100005,100009,100071,100074,100075]},{"name":"animeCategories","value":[]},{"name":"animeStandardFormatSearch","value":false},{"name":"additionalParameters"},{"name":"multiLanguages","value":[]},{"name":"minimumSeeders","value":1},{"name":"seedCriteria.seedRatio"},{"name":"seedCriteria.seedTime"},{"name":"seedCriteria.seasonPackSeedTime"},{"name":"rejectBlocklistedTorrentHashesWhileGrabbing","value":false}],"implementationName":"Torznab","implementation":"Torznab","configContract":"TorznabSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#torznab","tags":[]}' \
    -s -o /dev/null -w '%{http_code}\n'

# Add Nyaa.si
echo "Adding Nyaa.si"
curl "$SERVER/api/v3/indexer?" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $SONARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"enableRss":false,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"torrent","priority":25,"seasonSearchMaximumSingleEpisodeAge":0,"downloadClientId":0,"name":"Nyaa.si","fields":[{"name":"baseUrl","value":"http://localhost:9117/api/v2.0/indexers/nyaasi/results/torznab/"},{"name":"apiPath","value":"/api"},{"name":"apiKey","value":"'$JACKETT_API_KEY'"},{"name":"categories","value":[]},{"name":"animeCategories","value":[5070,125996,125996,127720,127720,131088,131088,140679,140679]},{"name":"animeStandardFormatSearch","value":false},{"name":"additionalParameters"},{"name":"multiLanguages","value":[]},{"name":"minimumSeeders","value":1},{"name":"seedCriteria.seedRatio","value":null},{"name":"seedCriteria.seedTime"},{"name":"seedCriteria.seasonPackSeedTime"},{"name":"rejectBlocklistedTorrentHashesWhileGrabbing","value":false}],"implementationName":"Torznab","implementation":"Torznab","configContract":"TorznabSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#torznab","tags":[]}' \
    -s -o /dev/null -w '%{http_code}\n'

# Add EZTV
echo "Adding EZTV"
curl "$SERVER/api/v3/indexer?" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $SONARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"torrent","priority":25,"seasonSearchMaximumSingleEpisodeAge":0,"downloadClientId":0,"name":"EZTV","fields":[{"name":"baseUrl","value":"http://localhost:9117/api/v2.0/indexers/eztv/results/torznab/"},{"name":"apiPath","value":"/api"},{"name":"apiKey","value":"'$JACKETT_API_KEY'"},{"name":"categories","value":[5000]},{"name":"animeCategories","value":[]},{"name":"animeStandardFormatSearch","value":false},{"name":"additionalParameters"},{"name":"multiLanguages","value":[]},{"name":"minimumSeeders","value":1},{"name":"seedCriteria.seedRatio"},{"name":"seedCriteria.seedTime"},{"name":"seedCriteria.seasonPackSeedTime"},{"name":"rejectBlocklistedTorrentHashesWhileGrabbing","value":false}],"implementationName":"Torznab","implementation":"Torznab","configContract":"TorznabSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#torznab","tags":[]}' \
    -s -o /dev/null -w '%{http_code}\n'

# Add Kickass.to
echo "Adding Kickass.to"
curl "$SERVER/api/v3/indexer?" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $SONARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"torrent","priority":25,"seasonSearchMaximumSingleEpisodeAge":0,"downloadClientId":0,"name":"Kickass.to","fields":[{"name":"baseUrl","value":"http://localhost:9117/api/v2.0/indexers/kickasstorrents-to/results/torznab/"},{"name":"apiPath","value":"/api"},{"name":"apiKey","value":"'$JACKETT_API_KEY'"},{"name":"categories","value":[103583]},{"name":"animeCategories","value":[5070,141745]},{"name":"animeStandardFormatSearch","value":false},{"name":"additionalParameters"},{"name":"multiLanguages","value":[]},{"name":"minimumSeeders","value":1},{"name":"seedCriteria.seedRatio"},{"name":"seedCriteria.seedTime"},{"name":"seedCriteria.seasonPackSeedTime"},{"name":"rejectBlocklistedTorrentHashesWhileGrabbing","value":false}],"implementationName":"Torznab","implementation":"Torznab","configContract":"TorznabSettings","infoLink":"https://wiki.servarr.com/sonarr/supported#torznab","tags":[]}' \
    -s -o /dev/null -w '%{http_code}\n'

echo "Sonarr first time run complete"
