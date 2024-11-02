#!/bin/sh

# Read environment variables
NODE_EXPORTER_TARGET=${NODE_EXPORTER_TARGET}
TRAEFIK_TARGET=${TRAEFIK_TARGET}
CLOUD_USER=${CLOUD_USER}
CLOUD_PASS=${CLOUD_PASS}

# Substitute environment variables into prometheus.yml using a temporary file
sed "s|\${NODE_EXPORTER_TARGET}|${NODE_EXPORTER_TARGET}|g; \
     s|\${TRAEFIK_TARGET}|${TRAEFIK_TARGET}|g; \
     s|\${CLOUD_USER}|${CLOUD_USER}|g; \
     s|\${CLOUD_PASS}|${CLOUD_PASS}|g" \
     /etc/prometheus/prometheus.yml.template > /etc/prometheus/prometheus.yml

# Start Prometheus with the updated configuration
/bin/prometheus --config.file=/etc/prometheus/prometheus.yml
