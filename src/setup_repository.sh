#!/bin/bash

if [[ -f .env ]]; then
    source .env
else
    log "ERROR: No se encontró un archivo .env"
    exit 1
fi

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
trap cleanup EXIT INT TERM

setup_repository_access() {
    log "Configurando acceso al repositorio..."

    # Determinamos si es que el repositorio es local o remoto
    if [[ "$REPO_URL" =~ ^https?:// ]] || [[ "$REPO_URL" =~ ^git@ ]]; then
        # Generamos un repositorio temporal a la vez lo clonamos
        TEMP_CLONE=$(mktemp -d)
        WORKING_REPO="$TEMP_CLONE"

        log "Clonando repositorio remoto: $REPO_URL"
        if ! git clone --quiet "$REPO_URL" "$TEMP_CLONE"; then
            log "ERROR: Fallo al clonar repositorio"
            exit 1
        fi

    else # Identificamos que es un repositorio local y verificamos si existe
        if [[ ! -d "$REPO_URL" ]]; then
            log "ERROR: Directorio local no existe: $REPO_URL"
            exit 1
        fi

        if [[ ! -d "$REPO_URL/.git" ]]; then
            log "ERROR: No es un repositorio Git: $REPO_URL"
            exit 1
        fi

        WORKING_REPO="$REPO_URL"
        log "Usando repositorio local: $REPO_URL"
    fi

    if ! git -C "$WORKING_REPO" status &>/dev/null; then
        log "ERROR: No se puede acceder al repositorio Git"
        exit 1
    fi

    log "Acceso al repositorio configurado: $WORKING_REPO"
}
