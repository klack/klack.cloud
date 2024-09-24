#!/bin/sh
# Read environment variables
HOST_IP=${HOST_IP}

# Substitute environment variables into dynamic_conf.yml using a temporary file
sed "s|\${HOST_IP}|${HOST_IP}|g; \
     s|\${INTERNAL_DOMAIN}|${INTERNAL_DOMAIN}|g" \
     /config/dynamic/dynamic_conf.yml.template > /config/dynamic/dynamic_conf.yml

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- traefik "$@"
fi

# if our command is a valid Traefik subcommand, let's invoke it through Traefik instead
# (this allows for "docker run traefik version", etc)
if traefik "$1" --help >/dev/null 2>&1
then
    set -- traefik "$@"
else
    echo "= '$1' is not a Traefik command: assuming shell execution." 1>&2
fi

exec "$@"
