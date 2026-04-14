#!/bin/sh

# Alertmanager Entrypoint with Soft Defaults
# This script ensures that environment variables used in alertmanager.yml
# have at least a dummy value before running envsubst.

# 1. Define defaults for required variables
export MSTEAMS_WEBHOOK_URL=${MSTEAMS_WEBHOOK_URL:-"http://localhost/dummy-msteams"}
export TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN:-"your_bot_token"}
export TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID:-"0"}
export SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-"http://localhost/dummy-slack"}
export SLACK_CHANNEL=${SLACK_CHANNEL:-"#alerts"}
export ALERT_EMAIL_TO=${ALERT_EMAIL_TO:-"admin@example.com"}
export SMTP_FROM=${SMTP_FROM:-"alertmanager@example.com"}
export SMTP_HOST=${SMTP_HOST:-"localhost:25"}
export SMTP_USER=${SMTP_USER:-"user"}
export SMTP_PASSWORD=${SMTP_PASSWORD:-"password"}
export LINE_WEBHOOK_URL=${LINE_WEBHOOK_URL:-"http://localhost/dummy-line"}

# 2. Expand variables in the configuration file
echo "Expanding environment variables in /etc/alertmanager/alertmanager.yml..."
envsubst < /etc/alertmanager/alertmanager.yml > /tmp/alertmanager.yml

# 3. Start Alertmanager
echo "Starting Alertmanager with expanded config..."
exec /bin/alertmanager --config.file=/tmp/alertmanager.yml "$@"
