.PHONY: up down purge lint help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  up      Build images and start the stack in detached mode"
	@echo "  down    Stop and remove containers (data volumes are preserved)"
	@echo "  purge   Stop and remove containers AND volumes (WARNING: deletes all data)"
	@echo "  lint    Run pre-commit hooks (security scan, YAML linting)"

# No separate 'build' target: every service uses a custom Dockerfile,
# so 'up' always rebuilds to ensure config changes are picked up.
up:
	docker compose up --build -d

down:
	docker compose down

purge:
	docker compose down -v

lint:
	pre-commit run --all-files
