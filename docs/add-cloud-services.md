# Adding cloud services (PostgreSQL, Redis, MySQL, …)

Beyond host-level metrics, you'll often want to monitor specific services
like PostgreSQL databases, Redis caches, or RabbitMQ brokers. Prometheus
does this through **exporters**: small processes that translate a service's
native stats into Prometheus-compatible metrics.

This guide walks through PostgreSQL as a worked example. The pattern is the
same for any other exporter.

## Pattern overview

1. Run the exporter close to (or alongside) the service it's monitoring.
2. Expose the exporter's metrics endpoint to the observatory.
3. Add a scrape job to `prometheus/prometheus.yml`.
4. Optionally add alert rules to `prometheus/rules/alert.rules.yml`.
5. Optionally install a Grafana dashboard.

## Example: PostgreSQL

### 1. Run postgres-exporter

Pick one of three common deployment styles:

**A. Same host as Postgres (systemd):**

```bash
POSTGRES_EXPORTER_VERSION=0.15.0
curl -sSL -o /tmp/pe.tar.gz \
  "https://github.com/prometheus-community/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION}/postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf /tmp/pe.tar.gz -C /tmp
sudo install /tmp/postgres_exporter-*/postgres_exporter /usr/local/bin/
```

Create a systemd unit with the connection string in an env file:

```ini
# /etc/systemd/system/postgres_exporter.service
[Unit]
Description=Prometheus PostgreSQL Exporter
After=network-online.target postgresql.service

[Service]
User=postgres
EnvironmentFile=/etc/postgres_exporter.env
ExecStart=/usr/local/bin/postgres_exporter --web.listen-address=0.0.0.0:9187
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
# /etc/postgres_exporter.env (mode 0600, owned by postgres)
DATA_SOURCE_NAME=postgresql://exporter_user:REPLACE_ME@localhost:5432/postgres?sslmode=disable  # pragma: allowlist secret
```

Create a read-only DB user for the exporter:

```sql
CREATE USER exporter_user WITH PASSWORD 'REPLACE_ME';  -- pragma: allowlist secret
GRANT pg_monitor TO exporter_user;
```

**B. Managed DB (RDS / Cloud SQL):** run the exporter on a small VM that
has network access to the DB.

**C. Kubernetes sidecar:** deploy `postgres-exporter` as a sidecar or as a
separate deployment in the same namespace.

### 2. Reach the exporter from the observatory

Same options as with `node_exporter` — private network, VPN mesh, or
reverse proxy. Port `9187` is the postgres-exporter default.

### 3. Add a scrape job

In `.env`:

```bash
POSTGRES_EXPORTER_ADDR=10.0.0.20:9187
POSTGRES_INSTANCE_NAME=primary
```

In `prometheus/entrypoint.sh`, export those with defaults and append them
to `VAR_LIST`:

```bash
export POSTGRES_EXPORTER_ADDR=${POSTGRES_EXPORTER_ADDR:-127.0.0.1:9187}
export POSTGRES_INSTANCE_NAME=${POSTGRES_INSTANCE_NAME:-primary}
# …
VAR_LIST='…,$POSTGRES_EXPORTER_ADDR,$POSTGRES_INSTANCE_NAME'
```

In `prometheus/prometheus.yml`:

```yaml
  - job_name: 'postgres'
    static_configs:
      - targets: ['${POSTGRES_EXPORTER_ADDR}']
        labels:
          db_type: postgres
          instance: '${POSTGRES_INSTANCE_NAME}'
```

### 4. Add alert rules

Append to `prometheus/rules/alert.rules.yml`:

```yaml
  - name: postgres-alerts
    rules:
      - alert: PostgreSQLDown
        expr: pg_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL down ({{ $labels.instance }})"
          description: Cannot connect to PostgreSQL on {{ $labels.instance }}.

      - alert: PostgreSQLHighConnections
        expr: pg_stat_activity_count / pg_settings_max_connections * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "PostgreSQL high connection usage on {{ $labels.instance }}"
```

### 5. (Optional) Grafana dashboard

Import dashboard ID `9628` ("PostgreSQL Database") from
<https://grafana.com/grafana/dashboards/> via the Grafana UI, or drop a
provisioned JSON file into `grafana/provisioning/dashboards/`.

## Other common exporters

| Service | Exporter | Default port |
|---------|------------------------------------|--------------|
| Redis | `oliver006/redis_exporter` | `9121` |
| MySQL | `prometheus/mysqld_exporter` | `9104` |
| MongoDB | `percona/mongodb_exporter` | `9216` |
| RabbitMQ | `kbudde/rabbitmq_exporter` | `9419` |
| Nginx | `nginx/nginx-prometheus-exporter` | `9113` |
| Blackbox | `prometheus/blackbox_exporter` | `9115` |
| Traefik | built-in `/metrics` endpoint | `8080` |
| HAProxy | built-in `/metrics` endpoint | `8404` |
| cAdvisor | `google/cadvisor` | `8080` |

The pattern is always the same: run the exporter → reach it from the
observatory → add a scrape job → (optionally) add rules + dashboard.
