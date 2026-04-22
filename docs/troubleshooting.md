# Troubleshooting

## Stack won't start

### `GF_ADMIN_USER is required` / `GF_ADMIN_PASSWORD is required`

Docker Compose refuses to start Grafana unless both are set in `.env`.
Copy the template and fill them in:

```bash
cp .env.example .env
$EDITOR .env   # set GF_ADMIN_USER and GF_ADMIN_PASSWORD
```

### `Permission denied` writing to `./data/prometheus` or `./data/grafana`

Bind-mounted folders inherit the host filesystem owner. The container
users (Prometheus UID `65534` / Grafana UID `472`) need write access.

Quick fix — create the folders with the right owner before `make up`:

```bash
mkdir -p data/prometheus data/grafana
sudo chown -R 65534:65534 data/prometheus
sudo chown -R 472:472     data/grafana
```

If you're on Docker Desktop (macOS / Windows), file-sharing sometimes
masks ownership — toggle the shared path in Settings → Resources →
File sharing.

### `port is already allocated`

Another process is bound to 3000 / 9090 / 9093 / 9100. Find it:

```bash
sudo lsof -i :3000
```

Either free the port or override it via `docker-compose.override.yml`:

```yaml
services:
  grafana:
    ports:
      - "127.0.0.1:3001:3000"
```

## Targets show as DOWN in Prometheus

Open <http://localhost:9090/targets> to see the exact error.

- **`context deadline exceeded`** — network unreachable. Check firewall /
  security group rules between the observatory host and the target.
- **`connection refused`** — the exporter isn't listening on that
  address. SSH to the target and run
  `ss -tlnp | grep 9100` (or the exporter's port).
- **`server returned HTTP status 401/403`** — the exporter has auth
  enabled. Either disable it or configure `basic_auth` in the scrape job.

## Alerts aren't firing

1. **Check the rule is loaded:**
   `http://localhost:9090/rules` — the expression should appear with its
   current value.
2. **Check the expression evaluates to truthy:** run the raw PromQL in
   the Prometheus UI (<http://localhost:9090/graph>). If the query
   returns no data, adjust it.
3. **Check Alertmanager received the alert:**
   <http://localhost:9093/#/alerts>. If it's there but not being
   delivered, look at Alertmanager logs:
   ```bash
   make logs | grep -i alertmanager
   ```
4. **Check the route matches:** use `amtool` to trace routing:
   ```bash
   docker compose exec alertmanager amtool config routes test \
     alertname=HighCPUUsage severity=warning
   ```

## Alerts fire but no notification arrives

- **Webhook returns non-2xx:** check the Alertmanager logs for the HTTP
  response. Many webhook proxies require a specific payload shape.
- **Grouping hid it:** Alertmanager groups alerts by `group_by` labels
  (default: `alertname, instance`). If a similar alert already fired,
  new ones are coalesced until `repeat_interval` (default 4h).
- **Silence is in effect:** check <http://localhost:9093/#/silences>.

## Dashboard shows "No data"

1. Open the Explore tab in Grafana and run `up` — you should see a
   series per scrape target. If empty, the datasource isn't working.
2. Check the datasource URL: it should be `http://prometheus:9090`
   (service name, not `localhost`) because containers share a Docker
   network.
3. Metric names can drift between exporter versions. For example, older
   `node_exporter` uses `node_memory_Free` while newer versions use
   `node_memory_MemFree_bytes`. Cross-check the names in Explore.

## Disk fills up

Prometheus stores TSDB in `./data/prometheus/`. Usage grows with
retention period and number of active series.

Check the current size:

```bash
du -sh data/prometheus
```

Options:

- **Reduce retention:** lower `PROMETHEUS_RETENTION` in `.env` and
  restart. Old blocks are purged on the next compaction.
- **Drop high-cardinality labels:** the biggest disk hog is usually a
  label with unbounded values (UUIDs, request IDs). Use
  `metric_relabel_configs` with a `drop` action to strip them.
- **Remote-write to long-term storage:** for production, stream metrics
  to Thanos, Mimir, or a managed Prometheus service instead of keeping
  everything locally.

## Grafana shows "database is locked" after restart

Occurs when Grafana was killed mid-write. Stop the stack, back up,
and repair:

```bash
make down
cp -a data/grafana data/grafana.bak
docker run --rm -v "$(pwd)/data/grafana:/var/lib/grafana" \
  --entrypoint sqlite3 keinos/sqlite3 \
  /var/lib/grafana/grafana.db "PRAGMA integrity_check; VACUUM;"
make up
```

## Getting more help

- Open a [Discussion](https://github.com/kittaweek/server-observatory/discussions)
  for usage questions.
- Open an [Issue](https://github.com/kittaweek/server-observatory/issues)
  for bugs (use the Bug report template — it asks for the info we need
  to help quickly).
- Never paste real tokens, webhook URLs, or internal IPs in public
  issues. Redact first.
