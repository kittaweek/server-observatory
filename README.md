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

## Troubleshooting

### Alerts not being delivered

- ตรวจสอบว่าสร้างไฟล์ `.env` และกรอก webhook/token ครบถ้วน
- Alertmanager ไม่ได้ expand env vars เอง — ต้องใช้ `envsubst` ใน entrypoint (ดู CRITICAL tasks ใน TASKS.md)
- ดู logs ด้วย: `docker logs alertmanager`

### Grafana เข้าไม่ได้

- รอ ~10 วินาทีหลัง `docker-compose up` ให้ Grafana start ก่อน
- ตรวจสอบ: `docker logs grafana`
- Default URL: `http://localhost:3000` (user: `admin`, pass: ดูใน `.env`)

### Prometheus ไม่เห็น metrics

- ตรวจสอบ targets ที่ `http://localhost:9090/targets`
- หาก `node-exporter` เป็น DOWN ให้รัน: `docker logs node-exporter`

### Container ไม่ขึ้น

```bash
docker-compose ps          # ดู status ทุก service
docker-compose logs -f     # ดู logs แบบ realtime
docker-compose down && docker-compose up -d  # restart ทั้งหมด
```
