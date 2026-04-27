TEMPORAL_SRC := $(abspath ../../src/temporal)
ALPINE_TAG   := 3.23.4
IMAGE        := temporal-server-local:latest

.PHONY: build up down restart logs migrate reset

build:
	cd $(TEMPORAL_SRC) && \
		GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o docker/build/arm64/temporal-server ./cmd/server
	docker build \
		-f $(TEMPORAL_SRC)/docker/targets/server.Dockerfile \
		--build-arg ALPINE_TAG=$(ALPINE_TAG) \
		--platform linux/arm64 \
		-t $(IMAGE) \
		$(TEMPORAL_SRC)/docker

up:
	docker compose up -d

down:
	docker compose down

restart: build
	docker compose up -d --no-deps --force-recreate temporal

logs:
	docker compose logs -f temporal

migrate:
	docker run --rm \
		--network temporal-network \
		-v $(TEMPORAL_SRC)/schema:/etc/temporal/schema:ro \
		temporalio/admin-tools:latest \
		sh -c '\
			temporal-sql-tool --plugin postgres12 --ep postgresql -u temporal -p 5432 --pw temporal --db temporal         update-schema -d /etc/temporal/schema/postgresql/v12/temporal/versioned && \
			temporal-sql-tool --plugin postgres12 --ep postgresql -u temporal -p 5432 --pw temporal --db temporal_visibility update-schema -d /etc/temporal/schema/postgresql/v12/visibility/versioned'

reset:
	docker compose down -v
