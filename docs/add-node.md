# Adding remote hosts to monitor

By default, Server Observatory only scrapes the local `node-exporter`
container. To monitor additional hosts, install the appropriate exporter
and add it to the relevant targets file — Prometheus reloads these files
automatically, no restart needed.

## Linux hosts (node_exporter)

### 1. Install node_exporter on the remote host

```bash
NE_VERSION=1.11.1
curl -sSL -o /tmp/ne.tar.gz \
  "https://github.com/prometheus/node_exporter/releases/download/v${NE_VERSION}/node_exporter-${NE_VERSION}.linux-amd64.tar.gz"
tar xzf /tmp/ne.tar.gz -C /tmp
sudo install /tmp/node_exporter-${NE_VERSION}.linux-amd64/node_exporter /usr/local/bin/
```

Create a systemd service:

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
curl -s http://localhost:9100/metrics | head -5   # verify
```

### 2. Make the port reachable from the observatory

- **Private network / VPC** — open port `9100` in your firewall / security group.
- **VPN mesh** (Tailscale / WireGuard) — use the mesh IP in the target entry.
- **SSH tunnel** (ad-hoc) — `ssh -L 9100:localhost:9100 user@remote`.

Do **not** expose `node_exporter` on the public internet without mTLS or an
authenticated reverse proxy.

### 3. Add the target to Prometheus

Edit `prometheus/targets/linux.yml` on the observatory host:

```yaml
- targets: ['10.0.0.10:9100']
  labels:
    name: web-server-1
    env: prod
```

Prometheus picks up the change within 30 seconds — no restart needed.
Confirm the target is `UP` at <http://localhost:9090/targets>.

### 4. Adding more Linux hosts

Just append more entries to the same file:

```yaml
- targets: ['10.0.0.10:9100']
  labels:
    name: web-server-1
    env: prod

- targets: ['10.0.0.11:9100']
  labels:
    name: db-server-1
    env: prod
```

---

## Windows hosts (windows_exporter)

### 1. Install windows_exporter on the Windows host

Download the latest MSI from
<https://github.com/prometheus-community/windows_exporter/releases> and
run it. The default install exposes metrics at `:9182`.

To enable additional collectors (e.g. process, tcp, time) pass them at
install time or via the service arguments:

```powershell
windows_exporter.exe --collectors.enabled="cpu,memory,net,logical_disk,physical_disk,os,system,service,process,tcp"
```

### 2. Make port 9182 reachable

Same options as Linux — VPN mesh is recommended for Windows hosts.

### 3. Add the Windows target to Prometheus

Edit `prometheus/targets/windows.yml`:

```yaml
- targets: ['10.0.0.20:9182']
  labels:
    name: workstation-1
    env: prod
```

Prometheus reloads within 30 seconds. Check <http://localhost:9090/targets>.
