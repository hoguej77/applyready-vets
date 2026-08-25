SHELL := /bin/zsh

.DEFAULT_GOAL := help

.PHONY: help setup build test test-live ai-quality backend start simulator-files stop doctor source-policy preflight app-store-preflight quality repair package site-draft-check site-release-check metadata-draft-check metadata-release-check app-store-draft-check app-store-release-check

help:
	@./scripts/applyready.command help

setup:
	HOGUE_NO_PAUSE=1 ./scripts/setup.command

build:
	HOGUE_NO_PAUSE=1 ./scripts/build-ios.command

test:
	HOGUE_NO_PAUSE=1 ./scripts/test-all.command

test-live:
	HOGUE_NO_PAUSE=1 ./scripts/test-simulator.command

ai-quality:
	HOGUE_NO_PAUSE=1 HOGUE_RUN_APPLE_MODEL_EVALUATION=1 ./scripts/test-simulator.command

backend:
	./scripts/run-backend.command

start:
	HOGUE_NO_PAUSE=1 ./scripts/start-everything.command

simulator-files:
	HOGUE_NO_PAUSE=1 ./scripts/open-simulator-files.command

stop:
	HOGUE_NO_PAUSE=1 ./scripts/stop-backend.command

doctor:
	HOGUE_NO_PAUSE=1 ./scripts/doctor.command

source-policy:
	HOGUE_NO_PAUSE=1 ./scripts/check-source-policy.command --self-test
	HOGUE_NO_PAUSE=1 HOGUE_PACKAGE_VALIDATE_ONLY=1 ./scripts/package-source.command

preflight:
	HOGUE_NO_PAUSE=1 ./scripts/release-preflight.command --release-candidate

app-store-preflight:
	HOGUE_NO_PAUSE=1 ./scripts/release-preflight.command --app-store

site-draft-check:
	./scripts/validate-launch-site.command --draft

site-release-check:
	./scripts/validate-launch-site.command --release

metadata-draft-check:
	./scripts/validate-app-store-metadata.command --draft

metadata-release-check:
	./scripts/validate-app-store-metadata.command --release

app-store-draft-check: preflight site-draft-check metadata-draft-check

app-store-release-check: app-store-preflight site-release-check metadata-release-check

quality:
	HOGUE_NO_PAUSE=1 ./scripts/quality-gate.command

repair:
	HOGUE_NO_PAUSE=1 ./scripts/repair-and-validate.command

package:
	HOGUE_NO_PAUSE=1 ./scripts/package-source.command
