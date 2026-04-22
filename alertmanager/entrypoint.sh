#!/bin/sh

# Telegram (default receiver)
export TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN:-"00000000:placeholder"}
export TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID:-"1"}

# Optional channels — only used if uncommented in alertmanager.yml
export MSTEAMS_WEBHOOK_URL=${MSTEAMS_WEBHOOK_URL:-"http://localhost/dummy-msteams"}
export SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-"http://localhost/dummy-slack"}
export SLACK_CHANNEL=${SLACK_CHANNEL:-"#alerts"}
export ALERT_EMAIL_TO=${ALERT_EMAIL_TO:-"admin@example.com"}
export SMTP_FROM=${SMTP_FROM:-"alertmanager@example.com"}
export SMTP_HOST=${SMTP_HOST:-"localhost:25"}
export SMTP_USER=${SMTP_USER:-"user"}
export SMTP_PASSWORD=${SMTP_PASSWORD:-"password"}
export LINE_WEBHOOK_URL=${LINE_WEBHOOK_URL:-"http://localhost/dummy-line"}
export LINE_WEBHOOK_TOKEN=${LINE_WEBHOOK_TOKEN:-"placeholder"}

echo "Expanding environment variables in /etc/alertmanager/alertmanager.yml..."
envsubst < /etc/alertmanager/alertmanager.yml > /tmp/alertmanager.yml

echo "Starting Alertmanager with expanded config..."
exec /bin/alertmanager \
    --config.file=/tmp/alertmanager.yml \
    --web.external-url=http://localhost:9093 \
    "$@"
