#!/bin/bash

echo -e "\nProvisioning Jackett"
source ./.env

SERVER="https://jackett.$INTERNAL_DOMAIN:4443"

# Wait for sonarr to be marked as healthy
echo "Waiting for Jackett to be healthy..."
CHECK_URL="$SERVER/UI/Dashboard"
TIMEOUT=60       # Maximum time to wait (in seconds)
RETRY_INTERVAL=5 # Time between retries
SECONDS_WAITED=0
until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' $CHECK_URL -H "Authorization: Basic $BASIC_AUTH_BASE64" -k)" == "302" ]]; do
    SECONDS_WAITED=$((SECONDS_WAITED + RETRY_INTERVAL))
    if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
        echo "Jackett did not return 302 after $SECONDS_WAITED seconds, exiting."
        exit 1
    fi
    echo "Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done

COOKIE=$(curl -k -H "Authorization: Basic $BASIC_AUTH_BASE64" -s -D - "$SERVER/UI/Login?cookiesChecked=1" | grep 'set-cookie:' | awk '{print $2}' | tr -d '\r')

# Add 1337x
echo "Adding 1337x"
curl "$SERVER/api/v2.0/indexers/1337x/config" \
    -k -X POST \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    -H "Cookie: $COOKIE" \
    --data-raw '[{"id":"sitelink","type":"inputstring","name":"Site Link","value":"https://1337x.to/"},{"id":"flaresolverr","type":"displayinfo","name":"FlareSolverr","value":"This site may use Cloudflare DDoS Protection, therefore Jackett requires <a href=\"https://github.com/Jackett/Jackett#configuring-flaresolverr\" target=\"_blan k\">FlareSolverr</a> to access it."},{"id":"downloadlink","type":"inputselect","name":"Download link","value":"http://itorrents.org/","options":{"http://itorrents.org/":"iTorrents.org","magnet:":"magnet"}},{"id":"downloadlink(fallback)","type":"inputselect","name":"Download link (fallback)","value":"magnet:","options":{"http://itorrents.org/":"iTorrents.org","magnet:":"magnet"}},{"id":"aboutthedownloadlinks","type":"displayinfo","name":"About the Download links","value":"As the iTorrents .torrent download link on this site is known to fail from time to time, we suggest using the magnet link as a fallback. The BTCache and Torrage services are not supported because they require additional user interaction (a captcha for BTCache and a download button on Torrage.)"},{"id":"sortrequestedfromsite","type":"inputselect","name":"Sort requested from site","value":"time","options":{"time":"created","seeders":"seeders","size":"size"}},{"id":"orderrequestedfromsite","type":"inputselect","name":"Order requested from site","value":"desc","options":{"desc":"desc","asc":"asc"}},{"id":"tags","type":"inputtags","name":"Tags","value":"","separator":",","delimiters":"[^A-Za-z0-9\\-\\._~]+","pattern":"^[A-Za-z0-9\\-\\._~]+$"}]' \
    -s -o /dev/null -w '%{http_code}\n'

# Add YTS
echo "Adding YTS"
curl "$SERVER/api/v2.0/indexers/yts/config" \
    -k -X POST \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    -H "Cookie: $COOKIE" \
    --data-raw '[{"id":"sitelink","type":"inputstring","name":"Site Link","value":"https://yts.mx/"},{"id":"tags","type":"inputtags","name":"Tags","value":"","separator":",","delimiters":"[^A-Za-z0-9\\-\\._~]+","pattern":"^[A-Za-z0-9\\-\\._~]+$"}]' \
    -s -o /dev/null -w '%{http_code}\n'

# Add Nyaa.si
echo "Adding Nyaa.si"
curl "$SERVER/api/v2.0/indexers/nyaasi/config" \
    -k -X POST \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    -H "Cookie: $COOKIE" \
    --data-raw '[{"id":"sitelink","type":"inputstring","name":"Site Link","value":"https://nyaa.si/"},{"id":"prefermagnetlinks","type":"inputbool","name":"Prefer Magnet Links","value":true},{"id":"improvesonarrcompatibilitybytryingtoaddseasoninformationintoreleasetitles","type":"inputbool","name":"Improve Sonarr compatibility by trying to add Season information into Release Titles","value":false},{"id":"removefirstseasonkeywords(s1/s01/season1),assomeresultsdonotincludethisforfirst/singleseasonreleases","type":"inputbool","name":"Remove first season keywords (S1/S01/Season 1), as some results do not include this for first/single season releases","value":false},{"id":"improveradarrcompatibilitybyremovingyearinformationfromkeywordsandaddingittoreleasetitles","type":"inputbool","name":"Improve Radarr compatibility by removing year information from keywords and adding it to Release Titles","value":false},{"id":"filter","type":"inputselect","name":"Filter","value":"0","options":{"0":"No filter","1":"No remakes","2":"Trusted only"}},{"id":"category","type":"inputselect","name":"Category","value":"0_0","options":{"0_0":"All categories","1_0":"Anime","1_1":"Anime - Anime Music Video","1_2":"Anime - English-translated","1_3":"Anime - Non-English-translated","1_4":"Anime - Raw","2_0":"Audio","2_1":"Audio - Lossless","2_2":"Audio - Lossy","3_0":"Literature","3_1":"Literature - English-translated","3_2":"Literature - Non-English-translated","3_3":"Literature - Lossy","4_0":"Live Action","4_1":"Live Action - English","4_2":"Live Action - Idol/PV","4_3":"Live Action - Non-English","4_4":"Live Action - Raw","5_0":"Pictures","5_1":"Pictures  - Graphics","5_2":"Pictures  - Photos","6_0":"Software","6_1":"Software - Applications","6_2":"Software - Games"}},{"id":"sortrequestedfromsite","type":"inputselect","name":"Sort requested from site","value":"id","options":{"id":"created","seeders":"seeders","size":"size"}},{"id":"orderrequestedfromsite","type":"inputselect","name":"Order requested from site","value":"desc","options":{"desc":"desc","asc":"asc"}},{"id":"tags","type":"inputtags","name":"Tags","value":"","separator":",","delimiters":"[^A-Za-z0-9\\-\\._~]+","pattern":"^[A-Za-z0-9\\-\\._~]+$"}]' \
    -s -o /dev/null -w '%{http_code}\n'

# Add EZTV
echo "Adding EZTV"
curl 'https://jackett.klack107.ddns.net.internal:4443/api/v2.0/indexers/eztv/config' \
    -k -X POST \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic $BASIC_AUTH_BASE64" \
    -H "Cookie: $COOKIE" \
    --data-raw '[{"id":"sitelink","type":"inputstring","name":"Site Link","value":"https://eztvx.to/"},{"id":"tags","type":"inputtags","name":"Tags","value":"","separator":",","delimiters":"[^A-Za-z0-9\\-\\._~]+","pattern":"^[A-Za-z0-9\\-\\._~]+$"}]' \
    -s -o /dev/null -w '%{http_code}\n'

echo "Jackett first time run complete"
