# Server Observatory

Self-hosted observability stack using **Prometheus**, **Grafana**, **Alertmanager**, and **Node Exporter**.

## Features
- Collects host metrics (CPU, RAM, Disk, Network)
- Pre-provisioned Grafana dashboard
- Alerting routes to: **MS Teams (Default)**, Telegram, Slack, Email, and LINE (via Webhook Proxy).

## Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kittaweek/server-observatory.git
   cd server-observatory
   ```

2. **Configure environment variables:**
   Copy `.env.example` to `.env` and fill in your details:
   ```bash
   cp .env.example .env
   # Edit .env and update tokens/webhooks
   ```

3. **Start the stack:**
   ```bash
   docker-compose up -d
   ```

## Dashboards
Grafana will auto-provision the "Server Overview" dashboard. Access it at `http://localhost:3000`.

## Alerting
- Critical: MS Teams + Telegram
- Warning: Telegram
- Configure notification URLs in `.env`.
