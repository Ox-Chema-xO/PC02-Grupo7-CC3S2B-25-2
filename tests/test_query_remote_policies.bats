#!/usr/bin/env bats
# test_query_remote_policies.bats
# Prueba GREEN para query-remote-policies.sh
# Valida cobertura de funcionalidad y exit codes correctos

setup() {
    export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../src" && pwd)"
    export PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export TEST_TEMP_DIR="$(mktemp -d)"

    mkdir -p "$PROJECT_ROOT/out/raw"
}

teardown() {
    cd "$PROJECT_ROOT" 2>/dev/null || true
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"
    [[ -d "$PROJECT_ROOT/out" ]] && rm -rf "$PROJECT_ROOT/out"
    [[ -f "$PROJECT_ROOT/.env" ]] && rm -f "$PROJECT_ROOT/.env"
}

# PRUEBA COBERTURA: Valida que query-remote-policies.sh detecta repositorio no-GitHub. Verifica comportamiento cuando REPO_URL no es de GitHub
@test "query-remote-policies.sh maneja correctamente repositorio no-GitHub" {
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="https://gitlab.com/test/repo.git"
PROTECTED_BRANCHES="main"
EOF

    run bash "$SCRIPT_DIR/query-remote-policies.sh"

    [[ $status -eq 0 ]]
    [[ "$output" =~ "No es un repositorio de GitHub" ]]
    [[ -f "$PROJECT_ROOT/out/raw/remote-branch-policies.csv" ]]
    grep -q "# No es repositorio de GitHub" "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
}

# PRUEBA COBERTURA: Valida advertencia cuando falta GITHUB_TOKEN. Verifica que se salta consulta cuando no hay token
@test "query-remote-policies.sh muestra advertencia cuando falta GITHUB_TOKEN para repo GitHub" {
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="https://github.com/torvalds/linux.git"
PROTECTED_BRANCHES="main,develop"
EOF

    run bash "$SCRIPT_DIR/query-remote-policies.sh"

    [[ $status -eq 0 ]]
    [[ "$output" =~ "GITHUB_TOKEN no configurado" ]]
    [[ -f "$PROJECT_ROOT/out/raw/remote-branch-policies.csv" ]]
    grep -q "# Sin token de GitHub configurado" "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
}

# PRUEBA COBERTURA: Valida manejo de patrones wildcard en PROTECTED_BRANCHES. Verifica que se saltan patrones con wildcard
@test "query-remote-policies.sh salta correctamente ramas con patrón wildcard" {
    cat > "$TEST_TEMP_DIR/curl" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "api.github.com" ]]; then
    echo '{"protected": true}'
    exit 0
fi
/usr/bin/curl "$@"
EOF
    chmod +x "$TEST_TEMP_DIR/curl"
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="https://github.com/test/repo.git"
PROTECTED_BRANCHES="main,feature/*,hotfix/*"
GITHUB_TOKEN="test_token"
EOF

    run env PATH="$TEST_TEMP_DIR:$PATH" bash "$SCRIPT_DIR/query-remote-policies.sh"

    [[ -f "$PROJECT_ROOT/out/raw/remote-branch-policies.csv" ]]
    grep -q "feature/\*|skipped|wildcard_pattern" "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
    grep -q "hotfix/\*|skipped|wildcard_pattern" "$PROJECT_ROOT/out/raw/remote-branch-policies.csv"
}

# PRUEBA EXIT CODE: Valida que query-remote-policies.sh falla cuando no hay REPO_URL. Verifica exit 1 cuando falta URL
@test "query-remote-policies.sh retorna EXIT_GENERIC (1) cuando falta REPO_URL" {
    cat > "$PROJECT_ROOT/.env" << EOF
PROTECTED_BRANCHES="main"
EOF

    run bash "$SCRIPT_DIR/query-remote-policies.sh"

    [[ $status -eq 1 ]]
    [[ "$output" =~ "Debe especificar la URL del repositorio" ]]
}
