#!/bin/sh
set -e

required_vars="MSTEAMS_WEBHOOK_URL TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID"

for var in $required_vars; do
  eval val=\$$var
  if [ -z "$val" ]; then
    echo "ERROR: Required environment variable '$var' is not set or empty."
    echo "Please copy .env.example to .env and fill in the required values."
    exit 1
  fi
done

envsubst < /etc/alertmanager/alertmanager.yml > /tmp/alertmanager.yml
exec /bin/alertmanager --config.file=/tmp/alertmanager.yml
