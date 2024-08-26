#!/bin/sh

# Read environment variables
NODE_EXPORTER_TARGET=${NODE_EXPORTER_TARGET}
NODE_EXPORTER_USER=${NODE_EXPORTER_USER}
NODE_EXPORTER_PASS=${NODE_EXPORTER_PASS}

# Substitute environment variables into prometheus.yml using a temporary file
sed "s|\${NODE_EXPORTER_TARGET}|${NODE_EXPORTER_TARGET}|g; \
     s|\${NODE_EXPORTER_USER}|${NODE_EXPORTER_USER}|g; \
     s|\${NODE_EXPORTER_PASS}|${NODE_EXPORTER_PASS}|g" \
     /etc/prometheus/prometheus.yml.template > /etc/prometheus/prometheus.yml

# Start Prometheus with the updated configuration
/bin/prometheus --config.file=/etc/prometheus/prometheus.yml
