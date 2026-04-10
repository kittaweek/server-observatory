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
- [x] Pre-commit hooks: end-of-file-fixer, trailing-whitespace, check-yaml, yamllint, gitleaks
- [x] Pre-commit autoupdate workflow (weekly, Monday, opens PR)
- [x] GitHub PR template
- [x] `docker-compose.override.yml.example` for local dev customization
- [x] Trivy vulnerability scan workflow (on push + weekly)
- [x] `Dockerfile.grafana` — patches vulnerable system packages
- [x] `Dockerfile.alertmanager` — rebuilds from source with updated Go dependencies

---

## 🔴 Must Fix (Blocking)

- [ ] **`Dockerfile.alertmanager`: uses `golang:1.25-alpine` which doesn't exist**
  - Go latest is 1.24.x — `1.25` is not released → Docker build will fail
  - Fix: change to `golang:1.24-alpine`

- [ ] **`docker-compose.yml`: still pulls `prom/alertmanager:v0.32.0` from Docker Hub**
  - `Dockerfile.alertmanager` builds a patched version but `docker-compose.yml` doesn't use it
  - The patch is never applied in production — fix by referencing the built image

- [ ] **`docker-compose.yml`: still pulls `grafana/grafana:12.4.2` from Docker Hub**
  - Same issue as above — `Dockerfile.grafana` patches the image but isn't used
  - Fix: build and reference local image in `docker-compose.yml`

- [ ] **CI `secret-scan` job references non-existent `.secrets.baseline`**
  - `ci.yml`: `detect-secrets-hook --baseline .secrets.baseline` — file doesn't exist
  - Fix: generate baseline with `detect-secrets scan > .secrets.baseline` and commit it, or remove job (gitleaks already covers this)

- [ ] **CI `validate-compose` copies non-existent files**
  - `ci.yml`: copies `dex-config.yaml.example` and `emails.txt.example` which don't exist in this repo
  - Fix: remove those two `cp` lines

- [ ] **CI `ci.yml` triggers on `main` but repo uses `master`**
  - Line 5: `branches: [main, dev]` → should be `[master, dev]`

---

## 🟠 Should Fix

- [ ] **CI `validate-compose`: should use dummy `.env` not copy `.env.example`**
  - `.env.example` has placeholder values that may fail `:?` validation
  - Fix: use explicit dummy values (same pattern as the old validate step)

- [ ] **CI: pre-commit cache removed after rewrite**
  - `actions/cache@v4` for pre-commit was dropped — CI installs hooks from scratch every run
  - Fix: add cache step keyed on `.pre-commit-config.yaml` hash

- [ ] **`Dockerfile.alertmanager`: full Go build on every CI run is slow (~3-5 min)**
  - Consider caching Go module downloads in CI with `actions/cache`

---

## 🟡 Nice to Have

- [ ] **Add `.trivyignore` file**
  - `trivy.yml` references `.trivyignore` but file doesn't exist — Trivy will warn
  - Create empty file or populate with known acceptable CVEs

- [ ] **`docker-compose.override.yml` committed to git**
  - `.gitignore` lists it but it was committed before that rule — should be untracked
  - Fix: `git rm --cached docker-compose.override.yml`

- [ ] **README: mention Dockerfiles and patched images**
  - README doesn't explain why `Dockerfile.grafana` / `Dockerfile.alertmanager` exist

- [ ] **Add `HEALTHCHECK` to Dockerfiles**
  - Healthchecks are in `docker-compose.yml` but not in the images themselves

---

## 🔵 Future / v2

- [ ] Loki + Promtail for log aggregation
- [ ] Blackbox Exporter for external HTTP monitoring
- [ ] Multi-node / remote write support
- [ ] Grafana SSO / LDAP
- [ ] Ansible playbook for provisioning
