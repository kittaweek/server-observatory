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

# Server identity (shown as `nodename` label in dashboards)
export MONITORING_SERVER_NAME=${MONITORING_SERVER_NAME:-observatory}

# Optional remote scrape target example (safe loopback defaults so the
# template still renders when the user hasn't configured a remote target).
export TARGET_1_ADDR=${TARGET_1_ADDR:-127.0.0.1:9100}
export TARGET_1_NAME=${TARGET_1_NAME:-local-node}

# 2. Define the whitelist for envsubst
# We MUST whitelist to prevent envsubst from destroying Prometheus internal tags like $labels, $value, etc.
VAR_LIST='$PROMETHEUS_SCRAPE_INTERVAL,$PROMETHEUS_EVALUATION_INTERVAL,$ALERT_CPU_THRESHOLD,$ALERT_MEMORY_THRESHOLD,$ALERT_DISK_THRESHOLD,$MONITORING_SERVER_NAME,$TARGET_1_ADDR,$TARGET_1_NAME'

echo "Expanding Prometheus configurations..."
mkdir -p /tmp/rules

envsubst "$VAR_LIST" < /etc/prometheus/prometheus.yml > /tmp/prometheus.yml

# Expand all rule files — static ones are copied, templated ones get envsubst
for f in /etc/prometheus/rules/*.rules.yml; do
    envsubst "$VAR_LIST" < "$f" > "/tmp/rules/$(basename "$f")"
done

# 3. Start Prometheus
echo "Starting Prometheus..."
exec /bin/prometheus \
    --config.file=/tmp/prometheus.yml \
    --storage.tsdb.path=/prometheus \
    --storage.tsdb.retention.time="$PROMETHEUS_RETENTION"
