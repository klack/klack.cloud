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
echo "Setting library path"
curl 'https://radarr.'"$INTERNAL_DOMAIN"':4443/api/v3/rootFolder' \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H 'X-Api-Key: '"$RADARR_API_KEY"'' \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    --data-raw '{"path":"/data/Library/Movies/"}'

# Setup qbittorrent as download client
curl 'https://radarr.'"$INTERNAL_DOMAIN"':4443/api/v3/downloadclient?' \
    -k \
    -X POST \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Content-Type: application/json' \
    -H 'X-Api-Key: '"$RADARR_API_KEY"'' \
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
    }'
    
#curl 'https://radarr.klack107.ddns.net.internal:4443/api/v3/qualityprofile/1?' --compressed -X PUT -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br, zstd' -H 'Content-Type: application/json' -H 'X-Api-Key: 497014a67ae97137ade78f855affbb8a' -H 'X-Requested-With: XMLHttpRequest' -H 'Origin: https://radarr.klack107.ddns.net.internal:4443' -H 'DNT: 1' -H 'Sec-GPC: 1' -H 'Authorization: Basic a2xhY2s6YXNkZg==' -H 'Connection: keep-alive' -H 'Referer: https://radarr.klack107.ddns.net.internal:4443/settings/profiles' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' -H 'Priority: u=0' -H 'TE: trailers' --data-raw '{"name":"Default","upgradeAllowed":false,"cutoff":1,"items":[{"quality":{"id":0,"name":"Unknown","source":"unknown","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":24,"name":"WORKPRINT","source":"workprint","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":25,"name":"CAM","source":"cam","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":26,"name":"TELESYNC","source":"telesync","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":27,"name":"TELECINE","source":"telecine","resolution":0,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":29,"name":"REGIONAL","source":"dvd","resolution":480,"modifier":"regional"},"items":[],"allowed":false},{"quality":{"id":28,"name":"DVDSCR","source":"dvd","resolution":480,"modifier":"screener"},"items":[],"allowed":false},{"quality":{"id":1,"name":"SDTV","source":"tv","resolution":480,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":2,"name":"DVD","source":"dvd","resolution":0,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":23,"name":"DVD-R","source":"dvd","resolution":480,"modifier":"remux"},"items":[],"allowed":false},{"name":"WEB 480p","items":[{"quality":{"id":8,"name":"WEBDL-480p","source":"webdl","resolution":480,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":12,"name":"WEBRip-480p","source":"webrip","resolution":480,"modifier":"none"},"items":[],"allowed":false}],"allowed":false,"id":1000},{"quality":{"id":20,"name":"Bluray-480p","source":"bluray","resolution":480,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":21,"name":"Bluray-576p","source":"bluray","resolution":576,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":4,"name":"HDTV-720p","source":"tv","resolution":720,"modifier":"none"},"items":[],"allowed":true},{"name":"WEB 720p","items":[{"quality":{"id":5,"name":"WEBDL-720p","source":"webdl","resolution":720,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":14,"name":"WEBRip-720p","source":"webrip","resolution":720,"modifier":"none"},"items":[],"allowed":true}],"allowed":true,"id":1001},{"quality":{"id":6,"name":"Bluray-720p","source":"bluray","resolution":720,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":9,"name":"HDTV-1080p","source":"tv","resolution":1080,"modifier":"none"},"items":[],"allowed":true},{"name":"WEB 1080p","items":[{"quality":{"id":3,"name":"WEBDL-1080p","source":"webdl","resolution":1080,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":15,"name":"WEBRip-1080p","source":"webrip","resolution":1080,"modifier":"none"},"items":[],"allowed":true}],"allowed":true,"id":1002},{"quality":{"id":7,"name":"Bluray-1080p","source":"bluray","resolution":1080,"modifier":"none"},"items":[],"allowed":true},{"quality":{"id":30,"name":"Remux-1080p","source":"bluray","resolution":1080,"modifier":"remux"},"items":[],"allowed":true},{"quality":{"id":16,"name":"HDTV-2160p","source":"tv","resolution":2160,"modifier":"none"},"items":[],"allowed":false},{"name":"WEB 2160p","items":[{"quality":{"id":18,"name":"WEBDL-2160p","source":"webdl","resolution":2160,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":17,"name":"WEBRip-2160p","source":"webrip","resolution":2160,"modifier":"none"},"items":[],"allowed":false}],"allowed":false,"id":1003},{"quality":{"id":19,"name":"Bluray-2160p","source":"bluray","resolution":2160,"modifier":"none"},"items":[],"allowed":false},{"quality":{"id":31,"name":"Remux-2160p","source":"bluray","resolution":2160,"modifier":"remux"},"items":[],"allowed":false},{"quality":{"id":22,"name":"BR-DISK","source":"bluray","resolution":1080,"modifier":"brdisk"},"items":[],"allowed":false},{"quality":{"id":10,"name":"Raw-HD","source":"tv","resolution":1080,"modifier":"rawhd"},"items":[],"allowed":false}],"minFormatScore":0,"cutoffFormatScore":0,"minUpgradeFormatScore":1,"formatItems":[],"language":{"id":1,"name":"English"},"id":1}'

echo "radarr first time run complete"