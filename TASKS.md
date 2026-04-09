# server-observatory — Task List

> Generated from code review. Organized by severity level.

---

## 🟢 LOW

- [ ] **Add `.gitignore` entries** — ไฟล์ว่างเปล่า เสี่ยง commit `.env` หรือ volume data ขึ้น git
  - เพิ่ม: `.env`, `prometheus_data/`, `grafana_data/`, `*.swp`, `*.bak`

- [ ] **Fix Naming inconsistency** — `node-exporter` ใช้ hyphen ขณะที่ service อื่น (`prometheus`, `grafana`, `alertmanager`) ไม่มี
  - แก้ service name และ `container_name` จาก `node-exporter` → `node_exporter` หรือ standardize ทั้งหมด

- [ ] **Enable Grafana datasource editing** — `editable: false` ใน `grafana/provisioning/datasources/prometheus.yml` ทำให้ปรับ Prometheus URL ใน UI ไม่ได้
  - เปลี่ยนเป็น `editable: true`

- [ ] **Add Docker logging limits** — ไม่มี log rotation ทำให้ disk เต็มได้ในระยะยาว
  - เพิ่ม `logging.driver` + `max-size`/`max-file` ทุก service

- [ ] **Consider mounting log volume** — `json-file` logs อยู่ที่ host (`/var/lib/docker/containers/`) และจะหายเมื่อ update image version (container ถูก recreate)
  - พิจารณา bind mount `./logs/` หรือ named volume สำหรับ log persistence

- [ ] **Add Troubleshooting section to README** — ไม่มีคำแนะนำเมื่อ alerts ไม่ส่ง หรือ service ไม่ขึ้น

---

## 🟡 MEDIUM

- [ ] **Complete Grafana Dashboard** — มีแค่ 2 panels (CPU, Memory) แต่ Spec กำหนด 6 panels
  - เพิ่ม: Disk Usage (gauge), Network I/O, System Load Average, Uptime

- [ ] **Pin service versions** — `grafana:latest`, `prom/prometheus:latest` ฯลฯ ควร pin เป็น specific version เช่น `grafana/grafana:10.4`

- [ ] **Add resource limits** — ไม่มี CPU/Memory limits ทำให้ service ใดก็ได้กิน resource ทั้งหมด
  - เพิ่ม `deploy.resources.limits` ทุก service

- [ ] **Fix or remove LINE receiver** — `alertmanager/alertmanager.yml` ชี้ไปที่ `http://line-bot-proxy:8080/notify` ซึ่งไม่มี service นี้
  - ตัดสินใจ: implement proxy service จริงๆ หรือ remove สำหรับ v1

- [ ] **Make scrape intervals configurable** — `prometheus/prometheus.yml` hard-code `15s`/`30s`
  - เปลี่ยนเป็น `${PROMETHEUS_SCRAPE_INTERVAL:-15s}`

- [ ] **Make alert thresholds configurable** — CPU 90%, Memory 90%, Disk 85% hard-coded ใน `prometheus/rules/alert.rules.yml`

---

## 🟠 HIGH

- [ ] **Add Healthchecks** — ไม่มี `healthcheck` สำหรับ Prometheus และ Grafana (Spec.md กำหนดให้ทำ)
  - Prometheus: `wget http://localhost:9090/-/healthy`
  - Grafana: `wget http://localhost:3000/api/health`

- [ ] **Implement Recording Rules** — `prometheus/rules/recording.rules.yml` ว่างเปล่า ทำให้ dashboard queries ช้า
  - เพิ่ม: `node:cpu:usage:rate5m`, `node:memory:usage:percent`, `node:disk:usage:percent`

- [ ] **Add missing `DiskWillFillIn4Hours` alert** — `prometheus/rules/alert.rules.yml` ขาด alert นี้ที่ Spec กำหนด
  - ใช้ `predict_linear(node_filesystem_free_bytes[1h], 4*3600) < 0`

- [ ] **Add `.env` validation** — ไม่มีการตรวจว่า required env vars ครบก่อน start service ทำให้ fail แบบ silent
  - สร้าง entrypoint script ที่ validate vars ก่อน exec

- [ ] **Strengthen default credentials** — `GF_SECURITY_ADMIN_PASSWORD=${GF_ADMIN_PASSWORD:-changeme}` fallback อ่อนแอ
  - ลบ default value หรือทำให้ fail ชัดเจนถ้าไม่มี `.env`

---

## 🔴 CRITICAL

- [ ] **Fix Alertmanager environment variable expansion** — Alertmanager ไม่ expand `${VAR}` เอง ทำให้ alerts ทุกช่องทาง (Teams, Telegram, Slack, Email, LINE) ไม่ทำงาน
  - แก้โดยเพิ่ม entrypoint ใน `docker-compose.yml`:
    ```yaml
    entrypoint: /bin/sh -c 'envsubst < /etc/alertmanager/alertmanager.yml > /tmp/alertmanager.yml && alertmanager --config.file=/tmp/alertmanager.yml'
    ```

- [ ] **Remove or fix `external-services` Prometheus job** — `prometheus/prometheus.yml` พยายาม scrape `google.com/metrics` ซึ่งไม่มี Prometheus metrics → error logs ต่อเนื่อง
  - ลบ job นี้ออก หรือ implement Blackbox Exporter อย่างถูกต้อง
