#!/bin/bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/utils.sh"

if [[ -f "$PROJECT_ROOT/.env" ]]; then
    source "$PROJECT_ROOT/.env"
else
    log "[policy-checker] ADVERTENCIA: No se encontró archivo .env"
fi

# Recibir repo del script_principal.sh
WORKING_REPO="$1"

main() {
    log "[policy-checker] Iniciando verificación de políticas..."

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
        log "[policy-checker] Ejecutando verificaciones pre-commit..."
        if ! "$PROJECT_ROOT/git-hooks/pre-commit"; then
            log "[policy-checker] Verificaciones pre-commit encontraron violaciones"
            exit_code=1
        fi
    else
        log "[policy-checker] ADVERTENCIA: Hook pre-commit no encontrado o no ejecutable"
    fi

    # Ejecutar hook commit-msg
    if [[ -x "$PROJECT_ROOT/git-hooks/commit-msg" ]]; then
        log "[policy-checker] Ejecutando verificaciones commit-msg..."
        if ! "$PROJECT_ROOT/git-hooks/commit-msg"; then
            log "[policy-checker] Verificaciones commit-msg encontraron violaciones"
            exit_code=1
        fi
    else
        log "[policy-checker] ADVERTENCIA: Hook commit-msg no encontrado o no ejecutable"
    fi

    # Ejecutar pre-receive simulado
    if [[ -x "$PROJECT_ROOT/git-hooks/pre-receive-sim" ]]; then
        log "[policy-checker] Ejecutando verificaciones pre-receive..."
        if ! "$PROJECT_ROOT/git-hooks/pre-receive-sim"; then
            log "[policy-checker] Verificaciones pre-receive encontraron violaciones"
            exit_code=1
        fi
    else
        log "[policy-checker] ADVERTENCIA: Hook pre-receive-sim no encontrado o no ejecutable"
    fi

    if [[ $exit_code -eq 0 ]]; then
        log "[policy-checker] Todas las políticas verificadas exitosamente"
    else
        log "[policy-checker] Se encontraron violaciones de políticas"
    fi

    return $exit_code
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
