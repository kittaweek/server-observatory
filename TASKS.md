# server-observatory — Task List

> Last reviewed: 2026-04-10. Reflects current state of codebase.

---

## ✅ Done

### Infrastructure

- [x] Docker Compose with shared network `observatory-net` and named volumes
- [x] Pin all image versions (prometheus v3.11.1, grafana 12.4.2, alertmanager v0.32.0, node-exporter v1.11.1)
- [x] CPU/Memory resource limits on all services
- [x] JSON file logging with rotation (`max-size: 10m`, `max-file: 3`)
- [x] Healthchecks on Prometheus and Grafana
- [x] `restart: unless-stopped` on all services

### Config & Security

- [x] `envsubst` entrypoint on Prometheus and Alertmanager for `${VAR}` expansion
- [x] Alertmanager `entrypoint.sh` validates required env vars before start
- [x] Grafana credentials require explicit `.env` (`:?` operator, no `changeme` fallback)
- [x] `.gitignore` covers `.env`, volume data, temp files, override file
- [x] Alert thresholds configurable via `ALERT_CPU/MEMORY/DISK_THRESHOLD`
- [x] Scrape intervals configurable via `PROMETHEUS_SCRAPE_INTERVAL/EVALUATION_INTERVAL`

### Alerting

- [x] Alert rules: InstanceDown, HighCpuUsage, HighMemoryUsage, HighDiskUsage, DiskWillFillIn4Hours
- [x] Recording rules: CPU, memory, disk, network
- [x] Alertmanager routing: default=MS Teams, critical=MS Teams+Telegram, warning=Telegram
- [x] All receivers use env vars: MS Teams, Telegram, Slack, Email, LINE

### Grafana

- [x] Auto-provisioned datasource (editable)
- [x] Dashboard with 6 panels: CPU, Memory, Disk gauge, Network I/O, Load Average, Uptime

### CI/CD & DevEx

- [x] Dependabot: Docker images + GitHub Actions (weekly, Monday)
- [x] Pre-commit hooks: end-of-file-fixer, trailing-whitespace, check-yaml, yamllint, gitleaks, black, isort, mypy, flake8, bandit, hadolint
- [x] Pre-commit autoupdate workflow (weekly, Monday, opens PR)
- [x] GitHub PR template
- [x] `docker-compose.override.yml.example` for local dev customization
- [x] Trivy vulnerability scan workflow (on push + weekly)
- [x] `Dockerfile.grafana` — patches vulnerable system packages
- [x] `Dockerfile.alertmanager` — rebuilds from source with updated Go dependencies (fixed to v1.24)
- [x] `Dockerfile.prometheus` — custom build for `envsubst` and healthchecks
- [x] `.secrets.baseline` — generated and tracked
- [x] `.trivyignore` — created to avoid false positives

---

## 🟢 Corrected (Previously Blocking)

- [x] **`Dockerfile.alertmanager`: uses `golang:1.25-alpine` which doesn't exist**
  - Fixed: changed to `golang:1.24-alpine`
- [x] **`docker-compose.yml`: still pulls `prom/alertmanager:v0.32.0` from Docker Hub**
  - Fixed: now uses `build: .`
- [x] **`docker-compose.yml`: still pulls `grafana/grafana:12.4.2` from Docker Hub**
  - Fixed: now uses `build: .`
- [x] **CI `secret-scan` job references non-existent `.secrets.baseline`**
  - Fixed: generated baseline and updated CI to use it.
- [x] **CI `validate-compose` copies non-existent files**
  - Fixed: removed invalid `cp` lines.
- [x] **CI `ci.yml` triggers on `main` but repo uses `master`**
  - Fixed: updated to `master`.

---

## 🟠 Should Fix

- [x] **CI `validate-compose`: should use dummy `.env` not copy `.env.example`**
  - Fixed: uses explicit dummy values in the script.
- [x] **CI: pre-commit cache restored**
  - Fixed: added `actions/cache@v4` back to CI.
- [ ] **`Dockerfile.alertmanager`: full Go build on every CI run is slow (~3-5 min)**
  - Consider caching Go module downloads in CI with `actions/cache` (Future)

---

## 🟡 Nice to Have

- [x] **Add `.trivyignore` file**
- [x] **`docker-compose.override.yml` committed to git**
  - Fixed: Untracked from Git index.
- [x] **README: mention Dockerfiles and patched images**
- [x] **Add `HEALTHCHECK` to Dockerfiles**

---

## 🔵 Future / v2

- [ ] Loki + Promtail for log aggregation
- [ ] Blackbox Exporter for external HTTP monitoring
- [ ] Multi-node / remote write support
- [ ] Grafana SSO / LDAP
- [ ] Ansible playbook for provisioning
