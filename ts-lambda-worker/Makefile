build-WorkerFunction:
	pnpm install --frozen-lockfile
	pnpm run build:bundle
	pnpm exec tsc --build --force
	cp dist/*.js $(ARTIFACTS_DIR)/
	cp package.json $(ARTIFACTS_DIR)/
	cp temporal.toml $(ARTIFACTS_DIR)/
	cp client.* $(ARTIFACTS_DIR)/
	cd $(ARTIFACTS_DIR) && npm install --omit=dev --ignore-scripts
	find $(ARTIFACTS_DIR)/node_modules/@temporalio/core-bridge/releases \
		-mindepth 1 -maxdepth 1 \
		! -name 'x86_64-unknown-linux-gnu' -exec rm -rf {} +
