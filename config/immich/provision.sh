#!/bin/bash -x

USER=admin@klack.cloud
PASSWORD=asdf

# # Create admin
# curl 'http://localhost:2283/api/auth/admin-sign-up' -X POST \
#     -H 'content-type: application/json' \
#     --data-raw '{"email":"$USER","password":"$PASSWORD","name":"Admin"}'

ACCESS_TOKEN=$(curl -s -L 'http://localhost:2283/api/auth/login' \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    --data-raw "{\"email\": \"$USER\", \"password\": \"$PASSWORD\"}" \
    | jq -r '.accessToken')

#{"accessToken":"UNvKU9HDWgIDiLtCHG5oeLPKhuzTR4ep2FwpORbMjmo","userId":"45ea349b-3765-478d-9cc7-9599b9a4f294","userEmail":"admin@klack.cloud","name":"My Name","isAdmin":true,"profileImagePath":"","shouldChangePassword":true}klack@suprim:~/projects/k
#curl 'http://localhost:2283/api/assets' -X POST -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br, zstd' -H 'Content-Type: multipart/form-data; boundary=---------------------------3177142945120919491761330671' -H 'Origin: http://localhost:2283' -H 'DNT: 1' -H 'Sec-GPC: 1' -H 'Connection: keep-alive' -H 'Referer: http://localhost:2283/photos' -H 'Cookie: immich_access_token=O15Hw2xaDVMsAg7AUGtyWOwKnS5IXYktzssTSDZMvk; immich_auth_type=password; immich_is_authenticated=true' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' --data-binary $'-----------------------------3177142945120919491761330671\r\nContent-Disposition: form-data; name="deviceAssetId"\r\n\r\nweb-dashboard.png-1726725269295\r\n-----------------------------3177142945120919491761330671\r\nContent-Disposition: form-data; name="deviceId"\r\n\r\nWEB\r\n-----------------------------3177142945120919491761330671\r\nContent-Disposition: form-data; name="fileCreatedAt"\r\n\r\n2024-09-19T05:54:29.295Z\r\n-----------------------------3177142945120919491761330671\r\nContent-Disposition: form-data; name="fileModifiedAt"\r\n\r\n2024-09-19T05:54:29.295Z\r\n-----------------------------3177142945120919491761330671\r\nContent-Disposition: form-data; name="isFavorite"\r\n\r\nfalse\r\n-----------------------------3177142945120919491761330671\r\nContent-Disposition: form-data; name="duration"\r\n\r\n0:00:00.000000\r\n-----------------------------3177142945120919491761330671\r\nContent-Disposition: form-data; name="assetData"; filename="dashboard.png"\r\nContent-Type: application/octet-stream\r\n\r\n-----------------------------3177142945120919491761330671--\r\n'
FILE='./config/immich/photo.png'
MTIME=$(stat -c %Y "$FILE")
DEVICE_ASSET_ID="${FILE}-${MTIME}"
FILE_CREATED_AT=$(date -d @$MTIME --utc +'%Y-%m-%dT%H:%M:%S.%NZ')
FILE_MODIFIED_AT=$(date -d @$MTIME --utc +'%Y-%m-%dT%H:%M:%S.%NZ')

curl -X POST "http://127.0.0.1:2283/api/assets" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -F "deviceAssetId=$DEVICE_ASSET_ID" \
    -F "deviceId=python" \
    -F "fileCreatedAt=$FILE_CREATED_AT" \
    -F "fileModifiedAt=$FILE_MODIFIED_AT" \
    -F "isFavorite=false" \
    -F "assetData=@$FILE"