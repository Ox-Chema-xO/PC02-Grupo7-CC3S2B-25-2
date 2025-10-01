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

readonly EXIT_SUCCESS=0
readonly EXIT_CONFIG=5

validate_environment() {
    log "Validando entorno..."

    # Herramientas requeridas
    local required_tools=("git" "jq" "curl" "grep" "awk" "sed" "cut" "sort" "uniq")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log "ERROR: Herramientas faltantes: ${missing_tools[*]}"
        exit $EXIT_CONFIG
    fi

    # Validar variables requeridas y formato
    [[ -n "${REPO_URL:-}" ]] || {
        log "ERROR: REPO_URL no definido"
        exit $EXIT_CONFIG
    }

    if [[ -n "${MIN_COMMIT_LENGTH:-}" ]] && ! [[ "$MIN_COMMIT_LENGTH" =~ ^[0-9]+$ ]]; then
        log "ERROR: MIN_COMMIT_LENGTH debe ser un número"
        exit $EXIT_CONFIG
    fi

    if [[ -n "${MAX_COMMIT_LENGTH:-}" ]] && ! [[ "$MAX_COMMIT_LENGTH" =~ ^[0-9]+$ ]]; then
        log "ERROR: MAX_COMMIT_LENGTH debe ser un número"
        exit $EXIT_CONFIG
    fi

    log "Entorno validado correctamente"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate_environment
fi
