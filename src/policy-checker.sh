#!/bin/bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() {
    echo "[policy-checker] $*" >&2
}

if [[ -f "$PROJECT_ROOT/.env" ]]; then
    source "$PROJECT_ROOT/.env"
else
    log "ADVERTENCIA: No se encontró archivo .env"
fi

# Repositorio a verificar
WORKING_REPO="${1:-${WORKING_REPO:-${REPO_URL:-}}}"

# Validar que existe el repositorio
if [[ -z "$WORKING_REPO" ]]; then
    log "ERROR: Debe especificar el repositorio a verificar"
    log "Uso: $0 <ruta_del_repositorio>"
    exit 1
fi

if [[ ! -d "$WORKING_REPO" ]]; then
    log "ERROR: Repositorio no existe: $WORKING_REPO"
    exit 1
fi

main() {
    log "Iniciando verificación de políticas..."

    local exit_code=0

    export WORKING_REPO
    export REPO_URL="${REPO_URL:-$WORKING_REPO}"
    export PROJECT_ROOT
    export PROTECTED_BRANCHES
    export REQUIRE_SIGNED_TAGS
    export MIN_COMMIT_LENGTH
    export MAX_COMMIT_LENGTH

    # Ejecutar hook pre-commit
    if [[ -x "$PROJECT_ROOT/git-hooks/pre-commit" ]]; then
        log "Ejecutando verificaciones pre-commit..."
        if ! "$PROJECT_ROOT/git-hooks/pre-commit"; then
            log "Verificaciones pre-commit encontraron violaciones"
            exit_code=1
        fi
    else
        log "ADVERTENCIA: Hook pre-commit no encontrado o no ejecutable"
    fi

    # Ejecutar hook commit-msg
    if [[ -x "$PROJECT_ROOT/git-hooks/commit-msg" ]]; then
        log "Ejecutando verificaciones commit-msg..."
        if ! "$PROJECT_ROOT/git-hooks/commit-msg"; then
            log "Verificaciones commit-msg encontraron violaciones"
            exit_code=1
        fi
    else
        log "ADVERTENCIA: Hook commit-msg no encontrado o no ejecutable"
    fi

    # Ejecutar pre-receive simulado
    if [[ -x "$PROJECT_ROOT/git-hooks/pre-receive-sim" ]]; then
        log "Ejecutando verificaciones pre-receive..."
        if ! "$PROJECT_ROOT/git-hooks/pre-receive-sim"; then
            log "Verificaciones pre-receive encontraron violaciones"
            exit_code=1
        fi
    else
        log "ADVERTENCIA: Hook pre-receive-sim no encontrado o no ejecutable"
    fi

    if [[ $exit_code -eq 0 ]]; then
        log "Todas las políticas verificadas exitosamente"
    else
        log "Se encontraron violaciones de políticas"
    fi

    return $exit_code
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
