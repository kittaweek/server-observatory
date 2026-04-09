# Server Observatory

Self-hosted observability stack using **Prometheus**, **Grafana**, **Alertmanager**, and **Node Exporter**.

## Features

- Collects host metrics: CPU, RAM, Disk, Network via Node Exporter
- Pre-provisioned Grafana dashboard — no manual UI setup required
- Alert routing to: **MS Teams** (default), Telegram, Slack, Email, LINE
- Fully file-based configuration via `.env` + YAML
- Environment variable expansion via `envsubst` at container startup

## Services

| Service | Image | Port |
| --- | --- | --- |
| Prometheus | prom/prometheus:v3.11.1 | 9090 |
| Grafana | grafana/grafana:12.4.2 | 3000 |
| Alertmanager | prom/alertmanager:v0.32.0 | 9093 |
| Node Exporter | prom/node-exporter:v1.11.1 | 9100 |

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/kittaweek/server-observatory.git
cd server-observatory
```

### 2. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` and fill in the required values:

| Variable | Required | Description |
| --- | --- | --- |
| `GF_ADMIN_USER` | Yes | Grafana admin username |
| `GF_ADMIN_PASSWORD` | Yes | Grafana admin password |
| `MSTEAMS_WEBHOOK_URL` | Yes | MS Teams incoming webhook URL |
| `TELEGRAM_BOT_TOKEN` | Yes | Telegram bot token |
| `TELEGRAM_CHAT_ID` | Yes | Telegram chat ID (integer) |
| `SLACK_WEBHOOK_URL` | No | Slack incoming webhook URL |
| `SLACK_CHANNEL` | No | Slack channel (e.g. `#alerts`) |
| `SMTP_HOST` | No | SMTP host and port (e.g. `smtp.gmail.com:587`) |
| `SMTP_FROM` | No | Sender email address |
| `SMTP_USER` | No | SMTP auth username |
| `SMTP_PASSWORD` | No | SMTP auth password |
| `ALERT_EMAIL_TO` | No | Alert recipient email address |
| `LINE_WEBHOOK_URL` | No | LINE webhook proxy URL |
| `PROMETHEUS_RETENTION` | No | Metrics retention period (default: `15d`) |
| `PROMETHEUS_SCRAPE_INTERVAL` | No | Scrape interval (default: `15s`) |
| `PROMETHEUS_EVALUATION_INTERVAL` | No | Rule evaluation interval (default: `15s`) |
| `ALERT_CPU_THRESHOLD` | No | CPU usage alert threshold % (default: `90`) |
| `ALERT_MEMORY_THRESHOLD` | No | Memory usage alert threshold % (default: `90`) |
| `ALERT_DISK_THRESHOLD` | No | Disk usage alert threshold % (default: `85`) |

> The stack will fail to start if `GF_ADMIN_USER`, `GF_ADMIN_PASSWORD`, `MSTEAMS_WEBHOOK_URL`, `TELEGRAM_BOT_TOKEN`, or `TELEGRAM_CHAT_ID` are not set.

### 3. Install pre-commit hooks (optional but recommended)

```bash
pip install pre-commit
pre-commit install
```

This runs YAML linting and secret detection on every commit.

### 4. Start the stack

```bash
docker-compose up -d
```

Access Grafana at `http://localhost:3000` with the credentials from your `.env`.

## Dashboard

Grafana auto-provisions the **Server Overview** dashboard with 6 panels:

| Panel | Type |
| --- | --- |
| CPU Usage (%) | Time series |
| Memory Usage (%) | Time series |
| Disk Usage (%) | Gauge |
| Network I/O (bytes/s) | Time series |
| System Load Average | Time series |
| System Uptime | Stat |

## Alert Rules

| Alert | Condition | Severity | For |
| --- | --- | --- | --- |
| InstanceDown | `up == 0` | critical | 1m |
| HighCpuUsage | CPU > `ALERT_CPU_THRESHOLD` | warning | 5m |
| HighMemoryUsage | Memory > `ALERT_MEMORY_THRESHOLD` | warning | 5m |
| HighDiskUsage | Disk > `ALERT_DISK_THRESHOLD` | warning | 10m |
| DiskWillFillIn4Hours | Predicted full within 4h | critical | 5m |

## Alert Routing

| Severity | Receivers |
| --- | --- |
| default | MS Teams |
| critical | MS Teams + Telegram |
| warning | Telegram |

Slack and Email receivers are pre-configured but not in the default route. Add them to `alertmanager/alertmanager.yml` routes as needed.

## Troubleshooting

### Alerts not being delivered

- Verify `.env` exists and all required variables are set
- Check Alertmanager logs: `docker logs alertmanager`
- Inspect active alerts: `http://localhost:9093`

### Cannot access Grafana

- Wait ~15 seconds after `docker-compose up` for Grafana to initialize
- Check logs: `docker logs grafana`
- Verify `GF_ADMIN_USER` and `GF_ADMIN_PASSWORD` are set in `.env`

### Prometheus not seeing metrics

- Check scrape targets: `http://localhost:9090/targets`
- Check node-exporter logs: `docker logs node-exporter`

### Service not starting

```bash
docker-compose ps           # check status of all services
docker-compose logs -f      # stream logs in real time
docker-compose down && docker-compose up -d  # restart the stack
```
