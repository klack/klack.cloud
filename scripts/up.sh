#!/bin/bash

if [ "$(basename "$(dirname "$PWD")")" = "scripts" ]; then
  cd ..
fi

# Check if ./config/wg0.conf exists
if [ -f "./config/wireguard/wg0.conf" ]; then
  # If wg0.conf exists, run docker compose with profile apps and downloaders
  docker compose --profile apps --profile downloaders up -d
else
  # If wg0.conf does not exist, run docker compose without the profiles
  docker compose --profile apps up -d
fi