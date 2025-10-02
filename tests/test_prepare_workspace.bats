#!/usr/bin/env bats
# test_prepare_workspace.bats
# Prueba GREEN para prepare_workspace.sh
# Valida cobertura de funcionalidad y exit codes correctos

setup() {
    export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../src" && pwd)"
    export PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export TEST_TEMP_DIR="$(mktemp -d)"

    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="https://github.com/test/repo.git"
PROTECTED_BRANCHES="main,develop"
REQUIRE_SIGNED_TAGS="false"
MIN_COMMIT_LENGTH="10"
MAX_COMMIT_LENGTH="72"
EOF
}

teardown() {
    cd "$PROJECT_ROOT" 2>/dev/null || true
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR" || true
    [[ -d "$PROJECT_ROOT/out" ]] && rm -rf "$PROJECT_ROOT/out" || true
    [[ -d "$PROJECT_ROOT/dist" ]] && rm -rf "$PROJECT_ROOT/dist" || true
    [[ -f "$PROJECT_ROOT/.env" ]] && rm -f "$PROJECT_ROOT/.env" || true
}

# PRUEBA COBERTURA: Valida creación correcta de estructura de directorios. Verifica creación de out/{raw,processed,reports} y dist/
@test "prepare_workspace.sh crea correctamente la estructura de directorios" {
    # ARRANGE: Ya tenemos .env configurado en setup()

    run bash "$SCRIPT_DIR/prepare_workspace.sh"

    [[ $status -eq 0 ]]
    [[ -d "$PROJECT_ROOT/out/raw" ]]
    [[ -d "$PROJECT_ROOT/out/processed" ]]
    [[ -d "$PROJECT_ROOT/out/reports" ]]
    [[ -d "$PROJECT_ROOT/dist" ]]
    [[ "$output" =~ "Espacio de trabajo preparado" ]]
}

# PRUEBA COBERTURA: Valida creación de archivo de configuración temporal. Verifica generación de out/audit-config.env con variables correctas
@test "prepare_workspace.sh genera archivo de configuración temporal con variables correctas" {
    # ARRANGE: Ya tenemos .env configurado en setup()

    run bash "$SCRIPT_DIR/prepare_workspace.sh"

    [[ -f "$PROJECT_ROOT/out/audit-config.env" ]]
    grep -q "AUDIT_TIMESTAMP=" "$PROJECT_ROOT/out/audit-config.env"
    grep -q "AUDIT_VERSION=1.0.0" "$PROJECT_ROOT/out/audit-config.env"
    grep -q "REPO_URL=https://github.com/test/repo.git" "$PROJECT_ROOT/out/audit-config.env"
    grep -q "PROTECTED_BRANCHES=main,develop" "$PROJECT_ROOT/out/audit-config.env"
    grep -q "REQUIRE_SIGNED_TAGS=false" "$PROJECT_ROOT/out/audit-config.env"
}

# PRUEBA EXIT CODE: Valida que prepare_workspace.sh falla cuando no existe .env. Verifica exit 1 cuando falta archivo de configuración
@test "prepare_workspace.sh retorna EXIT_GENERIC (1) cuando no existe archivo .env" {
    rm -f "$PROJECT_ROOT/.env"

    run bash "$SCRIPT_DIR/prepare_workspace.sh"

    [[ $status -eq 1 ]]
    [[ "$output" =~ "No se encontró archivo .env" ]]
}

# PRUEBA COBERTURA: Valida valores por defecto cuando faltan variables opcionales. Verifica que se usan valores por defecto correctos
@test "prepare_workspace.sh usa valores por defecto cuando faltan variables opcionales" {
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="https://github.com/test/minimal.git"
EOF

    run bash "$SCRIPT_DIR/prepare_workspace.sh"

    [[ -f "$PROJECT_ROOT/out/audit-config.env" ]]
    grep -q "PROTECTED_BRANCHES=main,develop" "$PROJECT_ROOT/out/audit-config.env"
    grep -q "REQUIRE_SIGNED_TAGS=false" "$PROJECT_ROOT/out/audit-config.env"
    grep -q "MIN_COMMIT_LENGTH=10" "$PROJECT_ROOT/out/audit-config.env"
    grep -q "MAX_COMMIT_LENGTH=72" "$PROJECT_ROOT/out/audit-config.env"
}
