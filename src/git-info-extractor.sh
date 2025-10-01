#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/utils.sh"

if [[ -f "$PROJECT_ROOT/.env" ]]; then
    source "$PROJECT_ROOT/.env"
fi

WORKING_REPO="${1:-${WORKING_REPO:-${REPO_URL:-}}}"

if [[ -z "$WORKING_REPO" ]]; then
    log "ERROR: Debe especificar el repositorio a analizar"
    log "Uso: $0 <ruta_del_repositorio>"
    log "O configurar REPO_URL en el archivo .env"
    exit 1
fi

if [[ ! -d "$WORKING_REPO" ]]; then
    log "ERROR: Repositorio no existe: $WORKING_REPO"
    exit 1
fi

extract_repository_info() {
    log "Extrayendo información del repositorio..."
    pushd "$WORKING_REPO" > /dev/null

    # Extraer información de ramas, commits, tags, reflog
    log "Extrayendo información de ramas..."
    git for-each-ref refs/heads/ --format='%(refname:short)' > "$PROJECT_ROOT/out/raw/local-branches.txt"
    git for-each-ref refs/remotes/ --format='%(refname:short)' > "$PROJECT_ROOT/out/raw/remote-branches.txt" 2>/dev/null || touch "$PROJECT_ROOT/out/raw/remote-branches.txt"

    log "Extrayendo información de commits..."
    git log --all --oneline --graph > "$PROJECT_ROOT/out/raw/commit-graph.txt"
    git log --all --pretty=format:'%H|%an|%ae|%ad|%s' --date=iso > "$PROJECT_ROOT/out/raw/commits.csv"

    log "Extrayendo información de tags..."
    if git tag -l | head -n 1 > /dev/null 2>&1; then
        git for-each-ref refs/tags/ --format='%(refname:short)|%(taggerdate)|%(taggername)|%(taggeremail)' > "$PROJECT_ROOT/out/raw/tags.csv"

        while IFS='|' read -r tag_name tag_date tag_author tag_email; do
            [[ -n "$tag_name" ]] || continue
            if git tag -v "$tag_name" &> /dev/null; then
                echo "$tag_name|signed|$tag_date|$tag_author" >> "$PROJECT_ROOT/out/raw/tag-signatures.csv"
            else
                echo "$tag_name|unsigned|$tag_date|$tag_author" >> "$PROJECT_ROOT/out/raw/tag-signatures.csv"
            fi
        done < "$PROJECT_ROOT/out/raw/tags.csv"
    else
        touch "$PROJECT_ROOT/out/raw/tags.csv"
        touch "$PROJECT_ROOT/out/raw/tag-signatures.csv"
    fi

    log "Extrayendo reflog..."
    git reflog --all --pretty=format:'%H|%gd|%gs|%ad' --date=iso > "$PROJECT_ROOT/out/raw/reflog.csv" 2>/dev/null || touch "$PROJECT_ROOT/out/raw/reflog.csv"

    popd > /dev/null

    log "Información del repositorio extraída"
    log "  - Ramas: out/raw/local-branches.txt, out/raw/remote-branches.txt"
    log "  - Commits: out/raw/commits.csv, out/raw/commit-graph.txt"
    log "  - Tags: out/raw/tags.csv, out/raw/tag-signatures.csv"
    log "  - Reflog: out/raw/reflog.csv"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    extract_repository_info
fi
