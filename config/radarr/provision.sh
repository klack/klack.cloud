#!/bin/bash

echo -e "\nProvisioning radarr"
source ./.env

# Wait for radarr to be marked as healthy
echo "Waiting for radarr to be healthy..."
SERVER="https://radarr.${INTERNAL_DOMAIN}:4443"
CHECK_URL="$SERVER"
TIMEOUT=60       # Maximum time to wait (in seconds)
RETRY_INTERVAL=5 # Time between retries
SECONDS_WAITED=0
until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' $CHECK_URL -H "Authorization: Basic $BASIC_AUTH_BASE64" -k)" == "200" ]]; do
    SECONDS_WAITED=$((SECONDS_WAITED + RETRY_INTERVAL))
    if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
        echo "radarr did not return 200 after $SECONDS_WAITED seconds, exiting."
        exit 1
    fi
    echo "Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done

# Setup Library Path
echo "Setting Movies path"
curl "$SERVER/api/v3/rootFolder" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"path":"/data/Library/Movies/"}' \
    -s -o /dev/null -w '%{http_code}\n'

# Setup qbittorrent as download client
echo "Adding qBittorrent as a download client"
curl "$SERVER/api/v3/downloadclient?" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $RADARR_API_KEY" \
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
            {"name": "movieCategory", "value": "radarr"},
            {"name": "movieImportedCategory"},
            {"name": "recentMoviePriority", "value": 0},
            {"name": "olderMoviePriority", "value": 0},
            {"name": "initialState", "value": 0},
            {"name": "sequentialOrder", "value": false},
            {"name": "firstAndLast", "value": false},
            {"name": "contentLayout", "value": 0}
        ],
        "implementationName": "qBittorrent",
        "implementation": "QBittorrent",
        "configContract": "QBittorrentSettings",
        "infoLink": "https://wiki.servarr.com/radarr/supported#qbittorrent",
        "tags": []
    }' \
    -s -o /dev/null -w '%{http_code}\n'

# Set default quality
echo "Setting default quality"
curl "$SERVER/api/v3/qualityprofile/1?" \
    -k \
    -X PUT \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"name":"Default","upgradeAllowed":false,"cutoff":1,"items":[{"quality":{"id":0,"name":"Unknown","source":"unknown","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":24,"name":"WORKPRINT","source":"workprint","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":25,"name":"CAM","source":"cam","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":26,"name":"TELESYNC","source":"telesync","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":27,"name":"TELECINE","source":"telecine","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":29,"name":"REGIONAL","source":"dvd","resolution":480,"modifier":"regional"},"items":[],"allowed":false},{"quality":{"id":28,"name":"DVDSCR","source":"dvd","resolution":480,"modifier":"screener"},"items":[],"allowed":false},{"quality":{"id":1,"name":"SDTV","source":"tv","resolution":480,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":2,"name":"DVD","source":"dvd","resolution":0,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":23,"name":"DVD-R","source":"dvd","resolution":480,"modifier":"remux"},"items":[],"allowed":false},{"name":"WEB 480p","items":[{"quality":{"id":8,"name":"WEBDL-480p","source":"webdl","resolution":480,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":12,"name":"WEBRip-480p","source":"webrip","resolution":480,"modifier":"none"},"items":[],"allowed":false}],"allowed":false,"id":1000},{"quality":{"id":20,"name":"Bluray-480p","source":"bluray","resolution":480,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":21,"name":"Bluray-576p","source":"bluray","resolution":576,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":4,"name":"HDTV-720p","source":"tv","resolution":720,"modifier":"none"},"items":[],"allowed":true},{"name":"WEB 720p","items":[{"quality":{"id":5,"name":"WEBDL-720p","source":"webdl","resolution":720,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":14,"name":"WEBRip-720p","source":"webrip","resolution":720,"modifier":"none"},"items":[],"allowed":true}],"allowed":true,"id":1001},{"quality":{"id":6,"name":"Bluray-720p","source":"bluray","resolution":720,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":9,"name":"HDTV-1080p","source":"tv","resolution":1080,"modifier":"none"},"items":[],"allowed":true},{"name":"WEB 1080p","items":[{"quality":{"id":3,"name":"WEBDL-1080p","source":"webdl","resolution":1080,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":15,"name":"WEBRip-1080p","source":"webrip","resolution":1080,"modifier":"none"},"items":[],"allowed":true}],"allowed":true,"id":1002},{"quality":{"id":7,"name":"Bluray-1080p","source":"bluray","resolution":1080,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":30,"name":"Remux-1080p","source":"bluray","resolution":1080,"modifier":"remux"},"items":[],"allowed":true},{"quality":{"id":16,"name":"HDTV-2160p","source":"tv","resolution":2160,"modifier":"none"},"items":[],"allowed":false},{"name":"WEB 2160p","items":[{"quality":{"id":18,"name":"WEBDL-2160p","source":"webdl","resolution":2160,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":17,"name":"WEBRip-2160p","source":"webrip","resolution":2160,"modifier":"none"},"items":[],"allowed":false}],"allowed":false,"id":1003},{"quality":{"id":19,"name":"Bluray-2160p","source":"bluray","resolution":2160,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":31,"name":"Remux-2160p","source":"bluray","resolution":2160,"modifier":"remux"},"items":[],"allowed":false},{"quality":{"id":22,"name":"BR-DISK","source":"bluray","resolution":1080,"modifier":"brdisk"},"items":[],"allowed":false},{"quality":{"id":10,"name":"Raw-HD","source":"tv","resolution":1080,"modifier":"rawhd"},"items":[],"allowed":false}],"minFormatScore":0,"cutoffFormatScore":0,"minUpgradeFormatScore":1,"formatItems":[],"language":{"id":1,"name":"English"},"id":1}' \
    -s -o /dev/null -w '%{http_code}\n'
echo "radarr first time run complete"

# Add 1337x
echo "Adding 1337x"
curl "$SERVER/api/v3/indexer?" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"torrent","priority":25,"downloadClientId":0,"name":"1337x","fields":[{"name":"baseUrl","value":"http://localhost:9117/api/v2.0/indexers/1337x/results/torznab/"},{"name":"apiPath","value":"/api"},{"name":"apiKey","value":"'$JACKETT_API_KEY'"},{"name":"categories","value":[2000,2010,2020,2030,2040,2045,2050,2060]},{"name":"additionalParameters"},{"name":"multiLanguages","value":[]},{"name":"removeYear","value":false},{"name":"minimumSeeders","value":1},{"name":"seedCriteria.seedRatio"},{"name":"seedCriteria.seedTime"},{"name":"rejectBlocklistedTorrentHashesWhileGrabbing","value":false},{"name":"requiredFlags","value":[]}],"implementationName":"Torznab","implementation":"Torznab","configContract":"TorznabSettings","infoLink":"https://wiki.servarr.com/radarr/supported#torznab","tags":[]}' \
    -s -o /dev/null -w '%{http_code}\n'

# Add YTS
echo "Adding YTS"
curl "$SERVER/api/v3/indexer?" \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"torrent","priority":25,"downloadClientId":0,"name":"YTS","fields":[{"name":"baseUrl","value":"http://localhost:9117/api/v2.0/indexers/yts/results/torznab/"},{"name":"apiPath","value":"/api"},{"name":"apiKey","value":"'$JACKETT_API_KEY'"},{"name":"categories","value":[2000,2010,2020,2030,2040,2045,2050,2060]},{"name":"additionalParameters"},{"name":"multiLanguages","value":[]},{"name":"removeYear","value":false},{"name":"minimumSeeders","value":1},{"name":"seedCriteria.seedRatio"},{"name":"seedCriteria.seedTime"},{"name":"rejectBlocklistedTorrentHashesWhileGrabbing","value":false},{"name":"requiredFlags","value":[]}],"implementationName":"Torznab","implementation":"Torznab","configContract":"TorznabSettings","infoLink":"https://wiki.servarr.com/radarr/supported#torznab","tags":[]}' \
    -s -o /dev/null -w '%{http_code}\n'

# Add Nyaa.si
echo "Nyaa.si"
curl 'https://radarr.klack107.ddns.net.internal:4443/api/v3/indexer?' \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $RADARR_API_KEY" \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"enableRss":true,"enableAutomaticSearch":true,"enableInteractiveSearch":true,"supportsRss":true,"supportsSearch":true,"protocol":"torrent","priority":25,"downloadClientId":0,"name":"Nyaa.si","fields":[{"name":"baseUrl","value":"http://localhost:9117/api/v2.0/indexers/nyaasi/results/torznab/"},{"name":"apiPath","value":"/api"},{"name":"apiKey","value":"'$JACKETT_API_KEY'"},{"name":"categories","value":[2000,2010,2020,2030,2040,2045,2050,2060]},{"name":"additionalParameters"},{"name":"multiLanguages","value":[]},{"name":"removeYear","value":false},{"name":"minimumSeeders","value":1},{"name":"seedCriteria.seedRatio","value":null},{"name":"seedCriteria.seedTime"},{"name":"rejectBlocklistedTorrentHashesWhileGrabbing","value":false},{"name":"requiredFlags","value":[]}],"implementationName":"Torznab","implementation":"Torznab","configContract":"TorznabSettings","infoLink":"https://wiki.servarr.com/radarr/supported#torznab","tags":[]}' \
    -s -o /dev/null -w '%{http_code}\n'

echo -e "Radarr first time run complete"
