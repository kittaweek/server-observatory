# Configuring alert channels

The stack ships with **Telegram as the default receiver**. MS Teams, Slack,
Email, and LINE are available as commented-out templates in
`alertmanager/alertmanager.yml`. To switch or add a channel:

1. Fill in the relevant variables in `.env`.
2. Set the receiver name in the `route.receiver` field of `alertmanager.yml`.
3. Uncomment the matching receiver block.
4. Run `docker compose restart alertmanager` (no rebuild needed — entrypoint re-expands the config on start).

Verify the config after every change:

```bash
docker compose exec alertmanager amtool check-config /tmp/alertmanager.yml
```

## Telegram (default)

1. Create a bot via [@BotFather](https://t.me/BotFather) → copy the token.
2. Add the bot to your group (or DM it) and send one message so a chat is created.
3. Find your `chat_id`:

   ```bash
   curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates" | jq '.result[].message.chat'
   ```

   Group chat IDs start with `-100`.

```bash
# .env
TELEGRAM_BOT_TOKEN=0000000000:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
TELEGRAM_CHAT_ID=-1000000000000
```

Active by default in `alertmanager.yml`:

```yaml
- name: 'telegram'
  telegram_configs:
    - bot_token: '${TELEGRAM_BOT_TOKEN}'
      chat_id: ${TELEGRAM_CHAT_ID}
      parse_mode: 'HTML'
      message: '{{ template "telegram.message" . }}'
```

The HTML message template lives in
`alertmanager/templates/telegram.tmpl`. It renders firing alerts in red 🔴
and resolved alerts in green ✅ with instance, severity, summary, and
description.

## Microsoft Teams (optional)

Teams accepts standard Prometheus webhook payloads via a webhook relay
(since native "Incoming Webhook" connectors are being deprecated by
Microsoft).

```bash
# .env
MSTEAMS_WEBHOOK_URL=https://your-teams-relay.example.com/webhook
```

Uncomment in `alertmanager.yml` and set as `receiver`:

```yaml
- name: 'msteams'
  webhook_configs:
    - url: '${MSTEAMS_WEBHOOK_URL}'
```

## Slack (optional)

Create an Incoming Webhook at
<https://api.slack.com/messaging/webhooks>.

```bash
# .env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXX
SLACK_CHANNEL=#alerts
```

Uncomment in `alertmanager.yml`:

```yaml
- name: 'slack'
  slack_configs:
    - api_url: '${SLACK_WEBHOOK_URL}'
      channel: '${SLACK_CHANNEL}'
      title: '{{ .CommonLabels.alertname }} on {{ .CommonLabels.instance }}'
      text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

## Email / SMTP (optional)

Works with any SMTP provider. For Gmail, use an
[App Password](https://support.google.com/accounts/answer/185833).

```bash
# .env
SMTP_HOST=smtp.gmail.com:587
SMTP_FROM=alert@example.com
SMTP_USER=alert@example.com
SMTP_PASSWORD=your_app_password
ALERT_EMAIL_TO=ops@example.com
```

Uncomment in `alertmanager.yml`:

```yaml
- name: 'email'
  email_configs:
    - to: '${ALERT_EMAIL_TO}'
      from: '${SMTP_FROM}'
      smarthost: '${SMTP_HOST}'
      auth_username: '${SMTP_USER}'
      auth_password: '${SMTP_PASSWORD}'
```

## LINE (optional — via webhook relay)

LINE Notify has been deprecated. The most reliable pattern is a small
relay (n8n, Cloudflare Worker, or a minimal FastAPI app) that accepts
the Alertmanager webhook payload and forwards it to the LINE Messaging API.

```bash
# .env
LINE_WEBHOOK_URL=https://your-line-relay.example.com/webhook
LINE_WEBHOOK_TOKEN=change_me_bearer_token
```

Uncomment in `alertmanager.yml`:

```yaml
- name: 'line'
  webhook_configs:
    - url: '${LINE_WEBHOOK_URL}'
      send_resolved: true
      http_config:
        authorization:
          type: Bearer
          credentials: '${LINE_WEBHOOK_TOKEN}'
```

## Routing rules

Route different severities or teams to different receivers:

```yaml
route:
  receiver: 'telegram'          # catch-all default
  group_by: ['alertname', 'instance']
  routes:
    - match:
        severity: critical
      receiver: 'telegram'
      repeat_interval: 1h       # re-notify every hour while firing
    - match:
        team: db
      receiver: 'slack'         # DB team has their own channel
```

Labels come from two places: **alert rule labels** (set in
`prometheus/rules/*.rules.yml`) and **target labels** (set under
`labels:` in `prometheus/targets/*.yml`). Keep label names consistent
so routing stays predictable.

## Testing without triggering real incidents

Send a synthetic alert directly to Alertmanager:

```bash
curl -s -H 'Content-Type: application/json' -XPOST \
  -d '[{"labels":{"alertname":"SmokeTest","severity":"warning"},"annotations":{"summary":"just a test"}}]' \
  http://localhost:9093/api/v2/alerts
```

Silence noisy alerts while iterating:

```bash
docker compose exec alertmanager amtool silence add \
  alertname=HighCpuUsage --duration=30m --comment='tuning thresholds'
```
