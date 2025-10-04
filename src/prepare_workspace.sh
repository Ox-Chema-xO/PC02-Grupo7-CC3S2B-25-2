#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/utils.sh"

if [[ -f "$PROJECT_ROOT/.env" ]]; then
    source "$PROJECT_ROOT/.env"
else
    log "ERROR: No se encontró archivo .env en $PROJECT_ROOT"
    exit 1
fi

readonly VERSION="1.0.0"

prepare_workspace() {
    log "Preparando espacio de trabajo..."

    cd "$PROJECT_ROOT"

    # Crear estructura de directorios
    mkdir -p out/{raw,reports}
    mkdir -p dist

    # Crear archivo de configuración temporal para la auditoría
    cat > out/audit-config.env << EOF
AUDIT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
AUDIT_VERSION=$VERSION
REPO_URL=${REPO_URL}
PROTECTED_BRANCHES=${PROTECTED_BRANCHES:-main,develop}
REQUIRE_SIGNED_TAGS=${REQUIRE_SIGNED_TAGS:-false}
MIN_COMMIT_LENGTH=${MIN_COMMIT_LENGTH:-10}
MAX_COMMIT_LENGTH=${MAX_COMMIT_LENGTH:-72}
EOF

    log "Espacio de trabajo preparado"
    log "  - Directorios: out/{raw,reports}, dist/"
    log "  - Configuración: out/audit-config.env"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    prepare_workspace
fi
