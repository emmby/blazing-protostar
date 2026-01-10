# Makefile for Blazing Protostar

.PHONY: test test-unit test-integration analyze format clean help

help:
	@echo "Usage:"
	@echo "  make test             - Run all unit and integration tests"
	@echo "  make test-unit        - Run all unit tests"
	@echo "  make test-integration - Run all integration tests (requires chromedriver)"
	@echo "  make analyze          - Run flutter analyze on all packages"
	@echo "  make format           - Run dart format on all packages"
	@echo "  make clean            - Clean all packages"

test: test-unit test-integration

test-unit:
	@echo "Running unit tests for blazing_protostar..."
	cd packages/blazing_protostar && flutter test
	@echo "Running unit tests for blazing_protostar_yjs..."
	cd packages/blazing_protostar_yjs && flutter test

test-integration:
	@echo "Running integration tests for blazing_protostar_yjs (Chrome)..."
	@# Check if chromedriver is running, if not start it
	@lsof -i :4444 > /dev/null || (chromedriver --port=4444 & sleep 2)
	cd packages/blazing_protostar_yjs/example && \
		flutter drive \
			--driver=test_driver/integration_test.dart \
			--target=integration_test/convergence_test.dart \
			-d chrome --headless
	@# Optional: Kill chromedriver if we started it
	@# killall chromedriver || true

analyze:
	cd packages/blazing_protostar && flutter analyze
	cd packages/blazing_protostar_yjs && flutter analyze
	cd packages/blazing_protostar_yjs/example && flutter analyze

format:
	cd packages/blazing_protostar && dart format .
	cd packages/blazing_protostar_yjs && dart format .
	cd packages/blazing_protostar_yjs/example && dart format .

clean:
	cd packages/blazing_protostar && flutter clean
	cd packages/blazing_protostar_yjs && flutter clean
	cd packages/blazing_protostar_yjs/example && flutter clean
