#!/usr/bin/env bats
# test_setup_repository.bats
# Prueba GREEN para setup_repository.sh - Sprint 1
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
    if [[ -n "${TEMP_CLONE:-}" ]] && [[ -d "$TEMP_CLONE" ]]; then
        rm -rf "$TEMP_CLONE"
    fi
}

# PRUEBA COBERTURA: Valida que setup_repository.sh funciona correctamente con repositorio local. Verifica detección de repositorio local y configuración de WORKING_REPO
@test "setup_repository.sh configura correctamente acceso a repositorio local válido" {
    mkdir -p "$TEST_TEMP_DIR/repo-local"
    cd "$TEST_TEMP_DIR/repo-local"
    git init --quiet
    git config user.name "Test"
    git config user.email "test@test.com"
    echo "test" > file.txt
    git add file.txt
    git commit -m "Initial commit" --quiet
    cd "$PROJECT_ROOT"
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="$TEST_TEMP_DIR/repo-local"
PROTECTED_BRANCHES="main"
EOF

    run bash -c "
        cd '$PROJECT_ROOT'
        source '$SCRIPT_DIR/setup_repository.sh'
        setup_repository_access
        echo \"WORKING_REPO=\$WORKING_REPO\"
    "

    [[ $status -eq 0 ]]
    [[ "$output" =~ "WORKING_REPO=$TEST_TEMP_DIR/repo-local" ]]
    [[ "$output" =~ "Usando repositorio local" ]]
}

# PRUEBA EXIT CODE: Valida que setup_repository.sh detecta repositorio local inexistente. Verifica código 1 cuando el directorio local no existe
@test "setup_repository.sh retorna EXIT_GENERIC (1) cuando directorio local no existe" {
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="$TEST_TEMP_DIR/directorio-inexistente"
PROTECTED_BRANCHES="main"
EOF

    run bash -c "
        cd '$PROJECT_ROOT'
        source '$SCRIPT_DIR/setup_repository.sh'
        setup_repository_access
        exit \$?
    "

    [[ $status -eq 1 ]]
    [[ "$output" =~ "Directorio local no existe" ]]
}

# PRUEBA EXIT CODE: Valida que setup_repository.sh detecta directorio que no es repositorio Git. Verifica código 1 cuando falta .git
@test "setup_repository.sh retorna EXIT_GENERIC (1) cuando directorio no es repositorio Git" {
    mkdir -p "$TEST_TEMP_DIR/no-git-repo"
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="$TEST_TEMP_DIR/no-git-repo"
PROTECTED_BRANCHES="main"
EOF

    run bash -c "
        cd '$PROJECT_ROOT'
        source '$SCRIPT_DIR/setup_repository.sh'
        setup_repository_access
        exit \$?
    "

    [[ $status -eq 1 ]]
    [[ "$output" =~ "No es un repositorio Git" ]]
}
