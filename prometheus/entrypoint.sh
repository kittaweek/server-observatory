#!/bin/sh

# Prometheus Entrypoint with Soft Defaults
# Ensures essential variables have values before expanding templates.

# 1. Provide defaults for expansion variables
export PROMETHEUS_SCRAPE_INTERVAL=${PROMETHEUS_SCRAPE_INTERVAL:-15s}
export PROMETHEUS_EVALUATION_INTERVAL=${PROMETHEUS_EVALUATION_INTERVAL:-15s}
export PROMETHEUS_RETENTION=${PROMETHEUS_RETENTION:-15d}
export ALERT_CPU_THRESHOLD=${ALERT_CPU_THRESHOLD:-90}
export ALERT_MEMORY_THRESHOLD=${ALERT_MEMORY_THRESHOLD:-90}
export ALERT_DISK_THRESHOLD=${ALERT_DISK_THRESHOLD:-85}

# 2. Define the whitelist for envsubst
# We MUST whitelist to prevent envsubst from destroying Prometheus internal tags like $labels, $value, etc.
VAR_LIST='$PROMETHEUS_SCRAPE_INTERVAL,$PROMETHEUS_EVALUATION_INTERVAL,$ALERT_CPU_THRESHOLD,$ALERT_MEMORY_THRESHOLD,$ALERT_DISK_THRESHOLD'

echo "Expanding Prometheus configurations..."
mkdir -p /tmp/rules

envsubst "$VAR_LIST" < /etc/prometheus/prometheus.yml > /tmp/prometheus.yml
envsubst "$VAR_LIST" < /etc/prometheus/rules/alert.rules.yml > /tmp/rules/alert.rules.yml

# Copy static rule files
if [ -f /etc/prometheus/rules/recording.rules.yml ]; then
    cp /etc/prometheus/rules/recording.rules.yml /tmp/rules/
fi

# 3. Start Prometheus
echo "Starting Prometheus..."
exec /bin/prometheus \
    --config.file=/tmp/prometheus.yml \
    --storage.tsdb.path=/prometheus \
    --storage.tsdb.retention.time="$PROMETHEUS_RETENTION"
