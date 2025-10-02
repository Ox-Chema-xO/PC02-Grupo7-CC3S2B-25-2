#!/usr/bin/env bats
# test_validate_environment.bats
# Prueba GREEN para validate_environment.sh - Sprint 1
# Valida cobertura de funcionalidad y exit codes correctos

setup() {
    export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../src" && pwd)"
    export PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
    cd "$PROJECT_ROOT" 2>/dev/null || true
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"
    [[ -f "$PROJECT_ROOT/.env" ]] && rm -f "$PROJECT_ROOT/.env"
}

# PRUEBA COBERTURA: Valida que validate_environment.sh verifica herramientas correctamente. Valida detección de todas las herramientas requeridas
@test "validate_environment.sh valida correctamente presencia de herramientas requeridas" {
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="https://github.com/test/repo.git"
PROTECTED_BRANCHES="main,develop"
REQUIRE_SIGNED_TAGS="false"
MIN_COMMIT_LENGTH="10"
MAX_COMMIT_LENGTH="72"
EOF

    run bash "$SCRIPT_DIR/validate_environment.sh"

    [[ $status -eq 0 ]]
    [[ "$output" =~ "Entorno validado correctamente" ]]
}

# PRUEBA COBERTURA: Valida que validate_environment.sh verifica lista de herramientas. Verifica que el script chequea todas las herramientas de la lista
@test "validate_environment.sh verifica todas las herramientas requeridas en la lista" {
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="https://github.com/test/repo.git"
PROTECTED_BRANCHES="main"
EOF

    run bash "$SCRIPT_DIR/validate_environment.sh"

    [[ $status -eq 0 ]]
    grep -q 'required_tools=("git" "jq" "curl"' "$SCRIPT_DIR/validate_environment.sh"
    grep -q '"grep" "awk" "sed" "cut" "sort" "uniq"' "$SCRIPT_DIR/validate_environment.sh"
}

# PRUEBA EXIT CODE: Valida que validate_environment.sh detecta REPO_URL faltante. Verifica EXIT_CONFIG (5) cuando falta variable requerida
@test "validate_environment.sh retorna EXIT_CONFIG (5) cuando REPO_URL no está definido" {
    cat > "$PROJECT_ROOT/.env" << EOF
PROTECTED_BRANCHES="main"
MIN_COMMIT_LENGTH="10"
EOF

    run bash "$SCRIPT_DIR/validate_environment.sh"

    [[ $status -eq 5 ]]
    [[ "$output" =~ "REPO_URL no definido" ]]
}

# PRUEBA EXIT CODE: Valida formato de variables numéricas. Verifica EXIT_CONFIG (5) cuando formato es inválido
@test "validate_environment.sh retorna EXIT_CONFIG (5) cuando MIN_COMMIT_LENGTH no es número" {
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="https://github.com/test/repo.git"
MIN_COMMIT_LENGTH="no_es_numero"
MAX_COMMIT_LENGTH="72"
EOF

    run bash "$SCRIPT_DIR/validate_environment.sh"

    [[ $status -eq 5 ]]
    [[ "$output" =~ "MIN_COMMIT_LENGTH debe ser un número" ]]
}
