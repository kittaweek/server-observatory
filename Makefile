.PHONY: up down purge lint logs restart help init

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  init     Create data/ folders required by bind-mount volumes"
	@echo "  up       Build images and start the stack in detached mode"
	@echo "  down     Stop and remove containers (data is preserved in ./data/)"
	@echo "  restart  Restart containers without rebuilding"
	@echo "  logs     Tail logs from all services"
	@echo "  purge    Stop containers AND delete ./data/ (WARNING: deletes all data)"
	@echo "  lint     Run pre-commit hooks (security scan, YAML linting)"

# Ensure bind-mount folders exist before containers try to write to them.
init:
	mkdir -p data/prometheus data/grafana

# No separate 'build' target: every service uses a custom Dockerfile,
# so 'up' always rebuilds to ensure config changes are picked up.
up: init
	docker compose up --build -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f --tail=200

# Purge wipes persistent data under ./data/ (and any legacy named volumes
# that may still be hanging around). Requires CONFIRM=yes to prevent
# accidental data loss.
purge:
	@if [ "$(CONFIRM)" != "yes" ]; then \
		echo "Refusing to purge: re-run with CONFIRM=yes to wipe ./data/ and named volumes."; \
		exit 1; \
	fi
	docker compose down -v
	rm -rf data/prometheus/* data/grafana/*

lint:
	pre-commit run --all-files
