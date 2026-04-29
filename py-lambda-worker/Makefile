build-WorkerFunction:
	uv pip install . \
	    --target $(ARTIFACTS_DIR) \
	    --python-platform aarch64-manylinux_2_17 \
	    --python-version 3.12
	mkdir -p $(ARTIFACTS_DIR)/app
	cp app/*.py $(ARTIFACTS_DIR)/app/
