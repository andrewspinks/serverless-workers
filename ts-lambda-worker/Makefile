CORE_BRIDGE_DIR := $(shell find node_modules/.pnpm -path '*/@temporalio/core-bridge/releases' -type d | head -1)

build-WorkerFunction:
	pnpm install --frozen-lockfile
	pnpm run build
	cp dist/* $(ARTIFACTS_DIR)/
	mkdir -p $(ARTIFACTS_DIR)/releases/aarch64-unknown-linux-gnu
	cp $(CORE_BRIDGE_DIR)/aarch64-unknown-linux-gnu/index.node $(ARTIFACTS_DIR)/releases/aarch64-unknown-linux-gnu/index.node
