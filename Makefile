# Makefile de analizador de ramas y politicas en repositorios

-include .env

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.DEFAULT_GOAL := help
export LC_ALL := C

SRC_DIR := src
TESTS_DIR := tests
OUT_DIR := out
DIST_DIR := dist
GIT_DIR := git-hooks

SRC_SCRIPTS := $(wildcard $(SRC_DIR)/*.sh)
TESTS_SCRIPTS := $(wildcard $(TESTS_DIR)/*.bats)

DIST_PACK := $(DIST_DIR)/repository-analyzer.tar

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

.PHONY: tools build test run pack clean help

tools: ## Verifica que todas las herramientas existan
	@$(SRC_DIR)/validate_environment.sh

build: tools ## Construcción de artefactos
	@$(SRC_DIR)/prepare_workspace.sh
	@chmod +x $(SRC_SCRIPTS) src/script_principal.sh 2>/dev/null || true

test: ## Ejecución de pruebas
	@echo "Ejecutando suite de pruebas..."
	@if [ -f .env ]; then \
		cp .env .env.backup; \
		trap 'mv .env.backup .env' EXIT; \
	fi; \
	bats $(TESTS_SCRIPTS)

run: build ## Ejecución del scaneo a repositorio
	@$(SRC_DIR)/script_principal.sh

pack: tools test $(DIST_DIR) ## Empaquetación del código
	@echo "Comprimiendo contenido del proyecto"
	@tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf $(DIST_PACK) $(SRC_DIR) $(GIT_DIR)
	@gzip -n -9 -c $(DIST_PACK) > $(DIST_PACK).gz

clean: ## Limpia artefactos creados
	@echo "Limpiando artefactos..."
	@rm -rf $(OUT_DIR) $(DIST_DIR)

help: ## Mostrar ayuda
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' Makefile | sort | awk -F':' '{split($$0, a, "## "); printf "\033[36m%-15s\033[0m %s\n", $$1, a[2]}'
