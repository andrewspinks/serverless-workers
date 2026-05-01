# core-bridge is a transitive dep of @temporalio/worker, so it doesn't get a top-level
# symlink in node_modules/@temporalio/. Resolve via the worker package's pnpm virtual-store
# entry, which always exposes a version-matched core-bridge symlink.
WORKER_PNPM_DIR := $(shell readlink node_modules/@temporalio/worker | awk -F/ '{print $$3}')
CORE_BRIDGE_RELEASES := node_modules/.pnpm/$(WORKER_PNPM_DIR)/node_modules/@temporalio/core-bridge/releases

build-WorkerFunction:
	pnpm install --frozen-lockfile
	pnpm run build
	cp dist/* $(ARTIFACTS_DIR)/
	mkdir -p $(ARTIFACTS_DIR)/releases/aarch64-unknown-linux-gnu
	cp $(CORE_BRIDGE_RELEASES)/aarch64-unknown-linux-gnu/index.node $(ARTIFACTS_DIR)/releases/aarch64-unknown-linux-gnu/index.node
