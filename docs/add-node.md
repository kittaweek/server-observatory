# Adding a remote host to monitor

By default, Server Observatory only scrapes the local `node-exporter`
container. To monitor additional Linux hosts, you install `node_exporter`
on each one and add it as a Prometheus target.

## 1. Install node_exporter on the remote host

On the host you want to monitor:

```bash
NE_VERSION=1.11.1
curl -sSL -o /tmp/ne.tar.gz \
  "https://github.com/prometheus/node_exporter/releases/download/v${NE_VERSION}/node_exporter-${NE_VERSION}.linux-amd64.tar.gz"
tar xzf /tmp/ne.tar.gz -C /tmp
sudo install /tmp/node_exporter-${NE_VERSION}.linux-amd64/node_exporter /usr/local/bin/
```

Create a systemd service (adjust user if you already have one):

```ini
# /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network-online.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter --web.listen-address=0.0.0.0:9100
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```

Verify it's serving metrics:

```bash
curl -s http://localhost:9100/metrics | head -5
```

## 2. Make the port reachable from the observatory

You have a few options — pick whichever fits your network:

- **Private network / VPC**: open port `9100` between the observatory host
  and the target (security group, firewall rule, etc.).
- **VPN mesh** (Tailscale / WireGuard): install the mesh client on both
  ends and use the mesh IP in the target URL.
- **SSH tunnel** (ad-hoc / single host): `ssh -L 9100:localhost:9100 user@remote`.

Do **not** expose `node_exporter` on the public internet without mTLS or a
reverse proxy with authentication.

## 3. Add the target to Prometheus

Edit `.env` on the observatory host and fill in one of the `TARGET_*`
slots:

```bash
TARGET_1_ADDR=10.0.0.10:9100
TARGET_1_NAME=web-server-1
```

Open `prometheus/prometheus.yml` and **uncomment** the `servers` job so it
looks like:

```yaml
  - job_name: 'servers'
    static_configs:
      - targets: ['${TARGET_1_ADDR}']
        labels:
          instance: '${TARGET_1_NAME}'
    metric_relabel_configs:
      - source_labels: [__name__, instance]
        regex: 'node_uname_info;(.*)'
        target_label: nodename
        replacement: '$1'
```

## 4. Apply the change

```bash
make up   # rebuilds prometheus with the updated template
```

Confirm the new target is `UP` at <http://localhost:9090/targets>.

## 5. Adding more targets

To monitor a second host, extend the entrypoint whitelist and add another
block:

1. In `.env`, add:
   ```bash
   TARGET_2_ADDR=10.0.0.11:9100
   TARGET_2_NAME=db-server-1
   ```
2. In `prometheus/entrypoint.sh`, add exports with defaults and append
   `$TARGET_2_ADDR,$TARGET_2_NAME` to `VAR_LIST`.
3. In `prometheus/prometheus.yml`, add a second target under the same job
   (or a new job if the hosts serve different roles / teams).

If you end up with many hosts, consider using Prometheus
[file_sd_configs](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#file_sd_config)
or a service discovery integration instead of listing targets inline.
