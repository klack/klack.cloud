#!/bin/bash
if [ "$(basename "$(dirname "$PWD")")" = "scripts" ]; then
  cd ..
fi
docker compose --profile apps --profile video --profile downloaders down
