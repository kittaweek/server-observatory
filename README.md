# 🛰️ Server Observatory Stack

A professional, minimal, and fully-containerized monitoring stack based on **Prometheus**, **Grafana**, and **Alertmanager**. Designed for high-reliability server monitoring with modern security practices.

## 🚀 Quick Start

1. **Clone and Setup**:
   ```bash
   git clone https://github.com/kittaweek/server-observatory.git
   cd server-observatory
   cp .env.example .env
   ```

2. **Edit `.env`** and fill in your credentials:
   ```bash
   # Required
   GF_ADMIN_USER=admin
   GF_ADMIN_PASSWORD=your_secure_password

   # Set at least one alert channel, e.g. MS Teams:
   MSTEAMS_WEBHOOK_URL=https://outlook.office.com/webhook/...
   ```

3. **Deploy**:
   ```bash
   make up
   ```

4. **Access** (localhost only by default):
   - **Grafana**: `http://localhost:3000` (login with credentials from `.env`)
   - **Prometheus**: `http://localhost:9090`
   - **Alertmanager**: `http://localhost:9093`

   > All ports are bound to `127.0.0.1` by default. To expose services on the network, see the remote access section in `docker-compose.override.yml.example`.

---

## 🏗️ Core Features

- **Built-in Security**: Custom Dockerfiles for Grafana and Alertmanager to patch upstream CVEs.
- **Dynamic Config**: Environment variable expansion (`${VAR}`) supported in all configuration files.
- **Pre-provisioned**: Automatic Grafana datasource and Linux monitoring dashboard.
- **Multi-channel Alerts**: Ready-to-use templates for MS Teams, Telegram, Slack, LINE, and Email.
- **Resource Constraints**: CPU/Memory limits applied to all services to prevent host exhaustion.

---

## ⚙️ Configuration (.env)

Edit the `.env` file to customize your stack. `GF_ADMIN_USER` and `GF_ADMIN_PASSWORD` are **required** — the stack will not start without them. Other variables have safe defaults built into the entrypoint scripts.

| Variable | Description | Default |
|----------|-------------|---------|
| `GF_ADMIN_USER` | Grafana Admin Username | **required** |
| `GF_ADMIN_PASSWORD` | Grafana Admin Password | **required** |
| `PROMETHEUS_SCRAPE_INTERVAL` | Metric collection frequency | `15s` |
| `MSTEAMS_WEBHOOK_URL` | Integration URL for MS Teams | `(dummy)` |

---

## 🔔 Setting Up Alerts

By default, only the **MS Teams** receiver is active (with a dummy URL). To enable other platforms:

1. Open `alertmanager/alertmanager.yml`.
2. Locate the receiver section for your platform (e.g., `# 🟠 Telegram`).
3. **Uncomment** the receiver block and update the `route` section to use that receiver.
4. Add your API keys/IDs to the `.env` file.
5. Run `make up` to apply changes.

---

## 💾 Persistence & Backup

Data is stored via **bind-mounts** under `./data/` so it's easy to back up,
inspect, and migrate:

- `./data/prometheus/` — time-series metric data
- `./data/grafana/` — dashboards, users, and plugin settings

The `./data/` tree is gitignored (only `.gitkeep` placeholders are tracked).
Back up with any standard tool, e.g. `tar czf backup.tgz data/`.

> [!CAUTION]
> Running `make purge` will **permanently delete** everything under `./data/`.
> Use `make down` to stop services safely without losing data.

### Migrating from named volumes (legacy layout)

Older versions of this stack used Docker named volumes (`prometheus_data`,
`grafana_data`). To migrate existing data:

```bash
# 1. Stop the stack (data is preserved in named volumes)
make down

# 2. Copy data out of the named volumes into the new bind-mount paths
docker run --rm -v prometheus_data:/from -v $(pwd)/data/prometheus:/to \
  alpine sh -c "cp -a /from/. /to/"
docker run --rm -v grafana_data:/from -v $(pwd)/data/grafana:/to \
  alpine sh -c "cp -a /from/. /to/"

# 3. Pull the latest version and start again
git pull && make up

# 4. Once verified healthy, remove the legacy named volumes
docker volume rm prometheus_data grafana_data
```

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
- **Rootless**: All services run as dedicated non-root users (`prometheus`, `alertmanager`, `grafana`) as defined in each Dockerfile.

---
*Created with ❤️ by the Devsiam Team.*
