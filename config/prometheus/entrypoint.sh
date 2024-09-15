#!/bin/sh

# Read environment variables
NODE_EXPORTER_TARGET=${NODE_EXPORTER_TARGET}
TRAEFIK_TARGET=${TRAEFIK_TARGET}
BASIC_AUTH_USER=${BASIC_AUTH_USER}
BASIC_AUTH_PASS=${BASIC_AUTH_PASS}

# Substitute environment variables into prometheus.yml using a temporary file
sed "s|\${NODE_EXPORTER_TARGET}|${NODE_EXPORTER_TARGET}|g; \
     s|\${TRAEFIK_TARGET}|${TRAEFIK_TARGET}|g; \
     s|\${BASIC_AUTH_USER}|${BASIC_AUTH_USER}|g; \
     s|\${BASIC_AUTH_PASS}|${BASIC_AUTH_PASS}|g" \
     /etc/prometheus/prometheus.yml.template > /etc/prometheus/prometheus.yml

# Start Prometheus with the updated configuration
/bin/prometheus --config.file=/etc/prometheus/prometheus.yml
