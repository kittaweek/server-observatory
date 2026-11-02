# server-observatory — Context สำหรับ AI

> เจ้าของ: Kittawee "Post" Kongpan (kittaweek) · repo ส่วนตัว · ตอบภาษาไทย สั้น กระชับ

## ใช้ทำอะไร
ชุด monitoring (Prometheus, Grafana, Loki, Alertmanager, process-exporter) ด้วย Docker Compose · repo **public** (MIT) อย่าใส่ข้อมูลภายใน

## โครงสร้าง
- `docker-compose.yml` (+ `docker-compose.override.yml.example`) · `Dockerfile.{prometheus,grafana,alertmanager}` · `prometheus/`, `grafana/`, `loki/`, `alertmanager/`, `process-exporter/`
- `data/` = bind mount (สร้างด้วย `make init`) · `docs/` · `CONTRIBUTING.md`

## คำสั่ง
- `make init` · `make up` · `make down` · `make logs` · `make lint`
- pre-commit: `pre-commit run --all-files` (yamllint, hadolint, gitleaks, detect-secrets)
- CI: lint + Trivy scan ทุก image · CVE ที่ยอมรับไว้ต้องอยู่ใน `.trivyignore` พร้อมเหตุผลและวันหมดอายุ

## หมายเหตุ
- dependabot รันวันจันทร์ 09:00 Asia/Bangkok · ไม่ target `dev`
- มี `devsiam-observatory` (private, All rights reserved) เป็นต้นฉบับแยก ห้ามคัดลอกโค้ด/ข้อมูลข้ามมาโดยไม่ถาม Post

## กฎ
- ห้าม push ตรงเข้า `main` → เปิด PR เสมอ · merge แบบ squash เท่านั้น · branch ที่ merge แล้วลบอัตโนมัติ
- AI ตรวจและสรุปได้ แต่ **ไม่ merge เอง** (Post เป็นคน merge) · ไม่ใช้ auto-merge
- CI ต้องเขียวก่อน merge
- ห้าม commit secret / `.env` / `*.bak` / ข้อมูลจริง · ใส่ค่าตัวอย่างใน `.env.example` เท่านั้น
- pin version ทุกอย่าง (image, package, action) · ห้าม `:latest`
- Branch: `<type>/<slug>` (feat, fix, docs, chore) · Commit: Conventional Commits
- `.claude/settings.local.json` อยู่ใน `.gitignore` · ห้าม commit
