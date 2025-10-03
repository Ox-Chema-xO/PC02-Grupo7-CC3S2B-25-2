#!/usr/bin/env bats
# test_script_principal.bats
# Prueba GREEN para script_principal.sh - Sprint 1
# Valida cobertura de funcionalidad y exit codes correctos

setup() {
    export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../src" && pwd)"
    export PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export TEST_TEMP_DIR="$(mktemp -d)"

    # Guardar directorio actual y cambiar al PROJECT_ROOT
    export ORIGINAL_DIR="$(pwd)"
    cd "$PROJECT_ROOT"

    # Crear repositorio Git de prueba válido
    mkdir -p "$TEST_TEMP_DIR/repo-valido"
    pushd "$TEST_TEMP_DIR/repo-valido" > /dev/null
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "contenido inicial" > file.txt
    git add file.txt
    git commit -m "Commit inicial para pruebas" --quiet
    popd > /dev/null

    # Crear archivo .env apuntando al repositorio válido
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="$TEST_TEMP_DIR/repo-valido"
PROTECTED_BRANCHES="main,develop"
REQUIRE_SIGNED_TAGS="false"
MIN_COMMIT_LENGTH="10"
MAX_COMMIT_LENGTH="72"
EOF
}

teardown() {
    cd "$PROJECT_ROOT"
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"
    [[ -d "$PROJECT_ROOT/out" ]] && rm -rf "$PROJECT_ROOT/out"
    [[ -d "$PROJECT_ROOT/dist" ]] && rm -rf "$PROJECT_ROOT/dist"
    [[ -f "$PROJECT_ROOT/.env" ]] && rm -f "$PROJECT_ROOT/.env"
    [[ -n "${ORIGINAL_DIR:-}" ]] && cd "$ORIGINAL_DIR"
}

# PRUEBA COBERTURA: Valida que script_principal.sh ejecuta correctamente el flujo completo. Valida todo el pipeline (validate, prepare, setup, extract, query, check, report)
@test "script_principal.sh ejecuta correctamente el flujo completo y retorna EXIT_SUCCESS (0)" {
    # ARRANGE: Ya tenemos repositorio válido y .env configurado en setup()

    run bash "$SCRIPT_DIR/script_principal.sh"

    [[ $status -eq 0 ]]
    [[ -f "$PROJECT_ROOT/out/raw/local-branches.txt" ]]
    [[ -f "$PROJECT_ROOT/out/raw/commits.csv" ]]
    [[ -f "$PROJECT_ROOT/out/raw/tags.csv" ]]
    [[ -f "$PROJECT_ROOT/out/reports/audit-summary.txt" ]]
    [[ "$output" =~ "Iniciando auditoría" ]]
    [[ "$output" =~ "Validando entorno" ]]
    [[ "$output" =~ "Preparando espacio de trabajo" ]]
    [[ "$output" =~ "Auditoría completada sin violaciones" ]]
}

# PRUEBA EXIT CODE: Valida que script_principal.sh falla correctamente cuando falta .env. Verifica EXIT_GENERIC (1) cuando falta configuración
@test "script_principal.sh retorna EXIT_GENERIC (1) cuando no existe archivo .env" {
    rm -f "$PROJECT_ROOT/.env"

    run bash "$SCRIPT_DIR/script_principal.sh"

    [[ $status -eq 1 ]]
    [[ "$output" =~ "No se encontró archivo .env" ]]
}
