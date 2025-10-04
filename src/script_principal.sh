#!/bin/bash
set -euo pipefail

# policy-auditor.sh
# Script principal de auditoría de políticas de repositorios Git

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly VERSION="1.0.0"

source "$SCRIPT_DIR/utils.sh"

# Cargar variables de entorno desde .env
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    source "$PROJECT_ROOT/.env"
else
    log "ERROR: No se encontró archivo .env"
    exit 1
fi

# Códigos de salida documentados
readonly EXIT_SUCCESS=0
readonly EXIT_GENERIC=1
readonly EXIT_NETWORK=2
readonly EXIT_GIT=3
readonly EXIT_VALIDATION=4
readonly EXIT_CONFIG=5

# Función principal
main() {
    log "Iniciando auditoría de políticas Git v$VERSION"

    # 1. Validar entorno
    "$SCRIPT_DIR/validate_environment.sh"

    # 2. Preparar espacio de trabajo
    "$SCRIPT_DIR/prepare_workspace.sh"

    # 3. Configurar acceso al repositorio
    source "$SCRIPT_DIR/setup_repository.sh"
    setup_repository_access

    # 4. Extraer información del repositorio
    "$SCRIPT_DIR/git-info-extractor.sh" "$WORKING_REPO"

    # 5. Consultar políticas remotas
    "$SCRIPT_DIR/query-remote-policies.sh"

    # 6. Verificar políticas (stub básico para Sprint 1)
    check_policies

    # 7. Generar reporte (stub básico para Sprint 1)
    generate_report

    # 8. Contar violaciones
    local violations_found
    violations_found=$(count_total_violations)

    if [[ $violations_found -gt 0 ]]; then
        log "Auditoría completada con $violations_found violaciones encontradas"
        exit $EXIT_VALIDATION
    else
        log "Auditoría completada sin violaciones"
        exit $EXIT_SUCCESS
    fi
}

# Verificación de políticas (implementación básica para Sprint 1)
check_policies() {
    log "Verificando políticas..."

    # Ejecutar policy-checker.sh si existe
    if [[ -x "$SCRIPT_DIR/policy-checker.sh" ]]; then
        "$SCRIPT_DIR/policy-checker.sh" "$WORKING_REPO" || true
    else
        log "ADVERTENCIA: policy-checker.sh no encontrado, saltando verificaciones de hooks"
    fi

    log "Políticas verificadas"
}

# Generación de reporte (implementación básica para Sprint 1)
generate_report() {
    log "Generando reporte..."

    # Crear reporte simple en texto
    cat > "$PROJECT_ROOT/out/reports/audit-summary.txt" << EOF
==============================================
REPORTE DE AUDITORÍA DE POLÍTICAS GIT
==============================================

Fecha: $(date)
Versión: $VERSION
Repositorio: ${REPO_URL}
Repositorio de trabajo: ${WORKING_REPO}

ARCHIVOS GENERADOS:
------------------
- Ramas locales: out/raw/local-branches.txt
- Ramas remotas: out/raw/remote-branches.txt
- Commits: out/raw/commits.csv
- Tags: out/raw/tags.csv
- Firmas de tags: out/raw/tag-signatures.csv
- Reflog: out/raw/reflog.csv
- Políticas remotas: out/raw/remote-branch-policies.csv

CONFIGURACIÓN UTILIZADA:
-----------------------
PROTECTED_BRANCHES: ${PROTECTED_BRANCHES}
REQUIRE_SIGNED_TAGS: ${REQUIRE_SIGNED_TAGS}
MIN_COMMIT_LENGTH: ${MIN_COMMIT_LENGTH}
MAX_COMMIT_LENGTH: ${MAX_COMMIT_LENGTH}

==============================================
EOF

    log "Reporte generado: out/reports/audit-summary.txt"
}

# Contar violaciones totales
count_total_violations() {
    local total_violations=0
    local reports_dir="$PROJECT_ROOT/out/reports"

    # Contar el total de líneas en todos los archivos de violaciones
    # usando find -exec para manejar correctamente nombres con espacios
    # Excluir líneas de comentarios (que empiezan con #) y líneas vacías
    total_violations=$(find "$reports_dir" -name "*-violations.txt" -type f -exec cat {} + 2>/dev/null | grep -v '^#' | grep -v '^[[:space:]]*$' | wc -l)

    echo "$total_violations"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
