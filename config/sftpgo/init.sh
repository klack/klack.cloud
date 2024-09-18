source ./.env
docker compose up sftpgo -d
sleep 5
PREFIX="./data/sftpgoroot/data/$CLOUD_USER"
mkdir -vp $PREFIX/Documents $PREFIX/Notes $PREFIX/Photos
mkdir -vp ./data/sftpgoroot/data/$CLOUD_USER
SERVER="https://sftpgo.${INTERNAL_DOMAIN}:4443"
BASE_64=$(echo -n "$BASIC_AUTH_USER:$BASIC_AUTH_PASS" | base64)
TOKEN_RESPONSE=$(curl -sS "$SERVER/api/v2/token" -H "Authorization: Basic $BASE_64" -H "Content-Type: application/json" -k)
TOKEN=$(echo $TOKEN_RESPONSE | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
sed "s|\${CLOUD_USER}|${CLOUD_USER}|g; \
     s|\${CLOUD_PASS}|${CLOUD_PASS}|g" \
     ./config/sftpgo/user.json.template > ./config/sftpgo/user.json
curl -X POST "$SERVER/api/v2/users" \
-k \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type: application/json" \
-d @./config/sftpgo/user.json