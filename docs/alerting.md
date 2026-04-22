# Configuring alert channels

The stack ships with a single active channel (Microsoft Teams) and
commented-out templates for the rest. To enable an additional channel,
you'll typically:

1. Fill in the relevant variables in `.env`.
2. Uncomment the matching receiver block in
   `alertmanager/alertmanager.yml`.
3. Route alerts to it via the `route` / `routes` stanza.
4. Run `make up` to rebuild Alertmanager with the new config.

After every change, verify the config:

```bash
docker compose exec alertmanager amtool check-config /tmp/alertmanager.yml
```

## Microsoft Teams

Teams accepts standard Prometheus webhook payloads via
[`prom2teams`](https://github.com/idealista/prom2teams) or a custom
webhook relay (since native "Incoming Webhook" connectors are being
deprecated).

```bash
# .env
MSTEAMS_WEBHOOK_URL=https://your-teams-relay.example.com/webhook
```

Already active by default in `alertmanager.yml`:

```yaml
- name: 'msteams'
  webhook_configs:
    - url: '${MSTEAMS_WEBHOOK_URL}'
```

## Slack

Create an Incoming Webhook at
<https://api.slack.com/messaging/webhooks>.

```bash
# .env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/<WORKSPACE_ID>/<CHANNEL_ID>/<TOKEN>
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

## Telegram

1. Create a bot via [@BotFather](https://t.me/BotFather) → copy the token.
2. Add the bot to your group (or DM it) and send one message.
3. Find your `chat_id`:
   ```bash
   curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates" | jq '.result[].message.chat'
   ```

```bash
# .env
TELEGRAM_BOT_TOKEN=0000000000:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
TELEGRAM_CHAT_ID=-1000000000000
```

Uncomment in `alertmanager.yml`:

```yaml
- name: 'telegram'
  telegram_configs:
    - bot_token: '${TELEGRAM_BOT_TOKEN}'
      chat_id: ${TELEGRAM_CHAT_ID}
      parse_mode: 'HTML'
```

## Email (SMTP)

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

## LINE (via webhook relay)

LINE Notify has been deprecated; the most reliable pattern is a small
relay (n8n, Cloudflare Worker, or a 50-line FastAPI app) that:

1. Accepts the Alertmanager webhook payload at a URL of your choice.
2. Formats each alert into a LINE Messaging API `push` call.
3. Optionally authenticates via a shared bearer token.

```bash
# .env
LINE_WEBHOOK_URL=https://your-line-relay.example.com/webhook
LINE_WEBHOOK_TOKEN=change_me_bearer_token
```

Uncomment / adjust in `alertmanager.yml`:

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

Once multiple receivers exist, route them based on labels. Example:

```yaml
route:
  receiver: 'msteams'          # catch-all fallback
  group_by: ['alertname', 'instance']
  routes:
    - match:
        severity: critical
      receiver: 'telegram'     # page loudly for critical
    - match:
        team: db
      receiver: 'slack'        # DB team has their own channel
```

Labels come from two places: **alert rule labels** (set in
`prometheus/rules/alert.rules.yml`) and **target labels** (set under
`labels:` in each scrape job). Keep label names consistent so routing
stays predictable.

## Testing without triggering real incidents

You can send a synthetic alert directly to Alertmanager:

```bash
curl -s -H 'Content-Type: application/json' -XPOST \
  -d '[{"labels":{"alertname":"SmokeTest","severity":"warning"},"annotations":{"summary":"just a test"}}]' \
  http://localhost:9093/api/v2/alerts
```

…or silence noisy alerts while you iterate:

```bash
docker compose exec alertmanager amtool silence add \
  alertname=HighCPUUsage --duration=30m --comment='tuning thresholds'
```
