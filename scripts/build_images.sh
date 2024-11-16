#!/bin/bash

# Get the architecture
ARCH=$(uname -m)

# Map architectures to platform strings
case "$ARCH" in
x86_64)
  PLATFORM="linux/amd64"
  ;;
aarch64)
  PLATFORM="linux/arm64"
  ;;
*)
  echo "Unsupported architecture: $ARCH"
  exit 1
  ;;
esac

#Build docker images
if [ $PLATFORM == "linux/arm64" ]; then
  echo -e "Building Plex"
  docker build --platform linux/arm64 --pull --no-cache -t plexinc/pms-docker ./config/plex/git
  echo -e "Building Dionaea"
  docker build --platform linux/arm64 --pull --no-cache -t dinotools/dionaea ./config/dionaea/git
  echo -e "Building qbittorrent-wireguard"
  docker build --platform linux/arm64 --pull --no-cache -t tenseiken/qbittorrent-wireguard ./config/qbittorrent/git
fi
