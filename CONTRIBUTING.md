# Contributing to Server Observatory

Thanks for your interest in improving Server Observatory! This document
describes how to propose changes and what we look for when reviewing them.

## Ways to contribute

- **Bug reports** — open an issue using the Bug report template.
- **Feature requests** — open an issue using the Feature request template.
- **Documentation** — README, migration notes, dashboards, and alerting
  recipes are all fair game.
- **Pull requests** — see below.

## Development setup

```bash
git clone https://github.com/kittaweek/server-observatory.git
cd server-observatory
cp .env.example .env       # edit GF_ADMIN_PASSWORD and any alert channels
make init                  # create ./data/ bind-mount folders
make up                    # build + start the stack
```

Grafana is on `http://localhost:3000`, Prometheus on `:9090`, Alertmanager on
`:9093`. All ports are bound to `127.0.0.1` by default.

## Code style & quality gates

Before opening a PR:

1. **Install hooks:** `pip install pre-commit && pre-commit install`
2. **Run linters:** `make lint` (runs yamllint, shellcheck, hadolint, gitleaks,
   detect-secrets).
3. **Validate configs:**
   - `docker compose config` — compose syntax
   - `promtool check config prometheus/prometheus.yml` — Prometheus syntax
   - `promtool check rules prometheus/rules/*.rules.yml` — alert rules
   - `amtool check-config alertmanager/alertmanager.yml` — Alertmanager syntax
4. **Smoke test:** `make up` and confirm all three services report healthy
   via `docker compose ps`.

## Pull request guidelines

- Keep PRs focused — one logical change per PR.
- Update `.env.example` if you add new environment variables, and export
  them in the relevant entrypoint script's `VAR_LIST` whitelist.
- Update `README.md` when user-visible behavior or layout changes.
- Describe **why** in the PR body, not just what — reviewers can read the
  diff, but they can't always infer the motivation.
- Never commit `.env`, real webhook URLs, API tokens, or internal IP
  addresses. `gitleaks` and `detect-secrets` run in CI, but please check
  your diff before pushing.

## Reporting security issues

Please **do not** open a public issue for security vulnerabilities. Instead,
email the maintainers directly (see `LICENSE` or repository metadata for
contact). We aim to respond within 72 hours.

## Commit messages

We use [Conventional Commits](https://www.conventionalcommits.org/) where
practical. Common prefixes:

- `feat:` — new user-visible capability
- `fix:` — bug fix
- `chore:` — tooling, CI, housekeeping
- `docs:` — documentation only
- `refactor:` — code change without behavior change

## License

By contributing, you agree that your contributions will be licensed under
the same license as this project (see `LICENSE`).
