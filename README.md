# 🛰️ Server Observatory Stack

A professional, minimal, and fully-containerized monitoring stack based on **Prometheus**, **Grafana**, and **Alertmanager**. Designed for high-reliability server monitoring with modern security practices.

![Grafana Dashboard Example](https://raw.githubusercontent.com/grafana/grafana/main/public/img/grafana_icon.svg) <!-- Placeholder for actual screenshot later -->

## 🚀 Quick Start

1. **Clone and Setup**:
   ```bash
   git clone <repo-url>
   cd server-observatory
   cp .env.example .env
   ```

2. **Deploy**:
   ```bash
   make up
   ```

3. **Access**:
   - **Grafana**: `http://localhost:3000` (Default: admin/admin)
   - **Prometheus**: `http://localhost:9090`
   - **Alertmanager**: `http://localhost:9093`

---

## 🏗️ Core Features

- **Built-in Security**: Custom Dockerfiles for Grafana and Alertmanager to patch upstream CVEs.
- **Dynamic Config**: Environment variable expansion (`${VAR}`) supported in all configuration files.
- **Pre-provisioned**: Automatic Grafana datasource and Linux monitoring dashboard.
- **Multi-channel Alerts**: Ready-to-use templates for MS Teams, Telegram, Slack, LINE, and Email.
- **Resource Constraints**: CPU/Memory limits applied to all services to prevent host exhaustion.

---

## ⚙️ Configuration (.env)

Edit the `.env` file to customize your stack. The system is designed with "Soft-defaults" — if you leave a variable empty, it will use a safe default instead of failing.

| Variable | Description | Default |
|----------|-------------|---------|
| `GF_ADMIN_USER` | Grafana Admin Username | `admin` |
| `GF_ADMIN_PASSWORD` | Grafana Admin Password | `admin` |
| `PROMETHEUS_SCRAPE_INTERVAL` | Metric collection frequency | `15s` |
| `MSTEAMS_WEBHOOK_URL` | Integration URL for MS Teams | `(dummy)` |

---

## 🔔 Setting Up Alerts

By default, only the **MS Teams** receiver is active (with a dummy URL). To enable other platforms:

1. Open `alertmanager/alertmanager.yml`.
2. Locate the receiver section for your platform (e.g., `# 🟠 Telegram`).
3. **Uncomment** the receiver block and update the `route` section to use that receiver.
4. Add your API keys/IDs to the `.env` file.
5. Run `make deploy` to apply changes.

---

## 💾 Persistence & Backup

Data is stored in **Named Docker Volumes** for high performance and isolation:
- `prometheus_data`: Stores all time-series metric data.
- `grafana_data`: Stores dashboards, users, and plugin settings.

> [!CAUTION]
> Running `docker compose down -v` will **permanently delete** your volumes. Use `make clean` (which maps to `docker compose down`) to stop services safely without losing data.

---

## 🛠️ Maintenance

Common tasks via `Makefile`:

- `make up`: Build images and start the stack in detached mode.
- `make down`: Stop services and remove containers (data volumes are **preserved**).
- `make purge`: Stop services and remove containers **and volumes** (⚠️ permanently deletes all data).
- `make lint`: Run pre-commit hooks (security scan, YAML linting).

---

## 🛡️ Security

This stack includes:
- **Trivy Scans**: Automated vulnerability scanning on every PR.
- **Gitleaks**: Native protection against committing sensitive credentials.
- **Rootless (Optional)**: While running as root for initial debug, Dockerfiles support dropping privileges to the `prometheus`/`grafana` users.

---
*Created with ❤️ by the Devsiam Team.*
