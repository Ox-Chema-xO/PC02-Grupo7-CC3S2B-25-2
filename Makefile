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
DOC_DIR := doc

SRC_SCRIPTS := $(wildcard $(SRC_DIR)/*.sh)
TESTS_SCRIPTS := $(wildcard $(TESTS_DIR)/*.bats)

DIST_PACK := $(DIST_DIR)/repository-analyzer.tar

NEED_TOOLS := git tar gzip curl bats grep awk sed

# Creación de directorios necesarios
$(OUT_DIR):
	@mkdir -p $(OUT_DIR)

$(DIST_DIR):
	@mkdir -p $(DIST_DIR)

.PHONY: tools build test run pack clean help

tools: ## Verifica que todas las herramientas existan
	@echo "Verificando herramientas requeridas..."
	@for tool in $(NEED_TOOLS); do \
	    command -v $$tool >/dev/null 2>&1 || { echo "ERROR: $$tool no fue encontrado"; exit 1; }; \
		echo "$$tool encontrado"; \
	done
	@echo "Todas las herramientas están disponibles"

build: tools $(OUT_DIR) ## Construcción de artefactos
	@echo "Construyendo scanner de politicas de repositorios..."
	# TODO (Construccion de scripts restantes)

test: build ## Ejecución de pruebas
	@echo "Ejecutando suite de pruebas..."
	@bats $(TESTS_SCRIPTS)

run: build ## Ejecución del scaneo a repositorio
	@echo "Ejecutando scaneo..."
	# TODO(Implementar script de ejecución principal)

pack: test $(DIST_DIR) ## Empaquetación del código
	@echo "Comprimiendo contenido del proyecto"
	@tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cf $(DIST_PACK) $(OUT_DIR)
	@gzip -n -9 -c $(DIST_PACK) > $(DIST_PACK).gz

clean: ## Limpia artefactos creados
	@echo "Limpiando artefactos..."
	@rm -rf $(OUT_DIR) $(DIST_DIR)

help: ## Mostrar ayuda
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' Makefile | sort | awk -F':' '{split($$0, a, "## "); printf "\033[36m%-15s\033[0m %s\n", $$1, a[2]}'
