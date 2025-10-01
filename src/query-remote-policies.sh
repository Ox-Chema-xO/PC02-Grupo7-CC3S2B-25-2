#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/utils.sh"

if [[ -f "$PROJECT_ROOT/.env" ]]; then
    source "$PROJECT_ROOT/.env"
fi

REPO_URL="${1:-${REPO_URL:-}}"

if [[ -z "$REPO_URL" ]]; then
    log "ERROR: Debe especificar la URL del repositorio"
    log "Uso: $0 <repo_url>"
    log "O configurar REPO_URL en el archivo .env"
    exit 1
fi

query_remote_policies() {
    log "Consultando políticas remotas..."

    local repo_owner repo_name

    # Extraer owner y repo
    if [[ "$REPO_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
        repo_owner="${BASH_REMATCH[1]}"
        repo_name="${BASH_REMATCH[2]}"

        log "Consultando políticas remotas para $repo_owner/$repo_name"

        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            # Consultar ramas protegidas
            local branches_to_check=()
            IFS=',' read -ra branches_to_check <<< "${PROTECTED_BRANCHES:-main,develop}"

            for branch in "${branches_to_check[@]}"; do
                branch=$(echo "$branch" | tr -d ' ')
                [[ -n "$branch" ]] || continue

                # Saltar patrones que no se puedan consultar directamente
                if [[ "$branch" == *"*"* ]]; then
                    echo "$branch|skipped|wildcard_pattern" >> "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
                    continue
                fi

                local api_url="https://api.github.com/repos/$repo_owner/$repo_name/branches/$branch"
                local response

                if response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "$api_url" 2>/dev/null); then
                    # Verificar si la respuesta contiene un error
                    if echo "$response" | jq -e '.message' &>/dev/null; then
                        echo "$branch|not_found|$(echo "$response" | jq -r '.message')" >> "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
                    else
                        local is_protected
                        is_protected=$(echo "$response" | jq -r '.protected')
                        if [[ "$is_protected" == "true" ]]; then
                            echo "$branch|protected|branch_protection_enabled" >> "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
                        else
                            echo "$branch|not_protected|no_protection_rules" >> "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
                        fi
                    fi
                else
                    echo "$branch|unknown|api_error" >> "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
                fi
            done

            log "Políticas remotas consultadas: out/raw/remote-branch-policies.csv"
        else
            log "ADVERTENCIA: GITHUB_TOKEN no configurado, saltando consulta de políticas remotas"
            echo "# Sin token de GitHub configurado" > "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
        fi
    else
        log "No es un repositorio de GitHub, saltando consulta de políticas remotas"
        echo "# No es repositorio de GitHub" > "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    query_remote_policies
fi
