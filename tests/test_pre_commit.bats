#!/usr/bin/env bats

setup() {
    export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../git-hooks" && pwd)"
    export PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export TEST_TEMP_DIR="$(mktemp -d)"

    mkdir -p "$PROJECT_ROOT/out/raw"
    mkdir -p "$PROJECT_ROOT/out/reports"

    # Crear repositorio de prueba
    mkdir -p "$TEST_TEMP_DIR/test-repo"
    cd "$TEST_TEMP_DIR/test-repo"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Crear commit inicial para que git diff-tree funcione
    echo "initial" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
}

teardown() {
    cd "$PROJECT_ROOT" 2>/dev/null || true
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR" || true
    [[ -d "$PROJECT_ROOT/out" ]] && rm -rf "$PROJECT_ROOT/out" || true
}

# TEST1: check_temporary_files detecta archivos .tmp en commits
@test "check_temporary_files detecta archivos temporales .tmp en commits" {
    # ARRANGE: Crear commit con archivo .tmp
    cd "$TEST_TEMP_DIR/test-repo"
    echo "temporal" > archivo.tmp
    git add archivo.tmp
    git commit -m "Commit con archivo temporal" --quiet

    local commit_hash=$(git rev-parse HEAD)
    local timestamp=$(date +%s)

    # Crear commits.csv
    echo "${commit_hash}|Test User|test@example.com|${timestamp}|Commit con archivo temporal" > "$PROJECT_ROOT/out/raw/commits.csv"

    # Volver al PROJECT_ROOT antes de ejecutar
    cd "$PROJECT_ROOT"
    export WORKING_REPO="$TEST_TEMP_DIR/test-repo"

    # ACT: Ejecutar pre-commit
    run bash "$SCRIPT_DIR/pre-commit"

    # ASSERT: Debe detectar violación
    [[ $status -eq 1 ]]
    [[ -f "$PROJECT_ROOT/out/reports/precommit-violations.txt" ]]
    grep -q "archivo.tmp" "$PROJECT_ROOT/out/reports/precommit-violations.txt"
}

# TEST2: check_script_shebangs detecta scripts sin shebang
@test "check_script_shebangs detecta scripts sin shebang" {
    # ARRANGE: Crear commit con script sin shebang
    cd "$TEST_TEMP_DIR/test-repo"
    cat > script_malo.sh << 'EOF'
echo "sin shebang"
EOF
    git add script_malo.sh
    git commit -m "Script sin shebang" --quiet

    local commit_hash=$(git rev-parse HEAD)
    local timestamp=$(date +%s)

    # Crear commits.csv con formato correcto
    echo "${commit_hash}|Test User|test@example.com|${timestamp}|Script sin shebang" > "$PROJECT_ROOT/out/raw/commits.csv"

    # Volver al PROJECT_ROOT antes de ejecutar
    cd "$PROJECT_ROOT"
    export WORKING_REPO="$TEST_TEMP_DIR/test-repo"

    # ACT: Ejecutar pre-commit
    run bash "$SCRIPT_DIR/pre-commit"

    # ASSERT: Debe detectar violación
    [[ $status -eq 1 ]]
    grep -q "sin shebang" "$PROJECT_ROOT/out/reports/precommit-violations.txt"
}

# TEST3: check_bash_syntax detecta errores de sintaxis
@test "check_bash_syntax detecta errores de sintaxis en scripts" {
    # ARRANGE: Crear script con error de sintaxis
    cd "$TEST_TEMP_DIR/test-repo"
    cat > script_error.sh << 'EOF'
#!/bin/bash
if [ test
    echo "sintaxis incorrecta"
EOF
    git add script_error.sh
    git commit -m "Script con error sintaxis" --quiet

    local commit_hash=$(git rev-parse HEAD)
    local timestamp=$(date +%s)

    # Crear commits.csv con formato correcto
    echo "${commit_hash}|Test User|test@example.com|${timestamp}|Script con error sintaxis" > "$PROJECT_ROOT/out/raw/commits.csv"

    # Volver al PROJECT_ROOT antes de ejecutar
    cd "$PROJECT_ROOT"
    export WORKING_REPO="$TEST_TEMP_DIR/test-repo"

    # ACT: Ejecutar pre-commit
    run bash "$SCRIPT_DIR/pre-commit"

    # ASSERT: Debe detectar error de sintaxis
    [[ $status -eq 1 ]]
    grep -q "script_error.sh" "$PROJECT_ROOT/out/reports/precommit-violations.txt"
}

# TEST INTEGRACIÓN: pre-commit retorna exit 0 cuando no hay violaciones
@test "pre-commit retorna exit 0 cuando no hay violaciones" {
    # ARRANGE: Crear commit limpio
    cd "$TEST_TEMP_DIR/test-repo"
    cat > script_bueno.sh << 'EOF'
#!/bin/bash
echo "Script correcto"
EOF
    git add script_bueno.sh
    git commit -m "Script correcto" --quiet

    local commit_hash=$(git rev-parse HEAD)
    local timestamp=$(date +%s)

    # Crear commits.csv con formato correcto
    echo "${commit_hash}|Test User|test@example.com|${timestamp}|Script correcto" > "$PROJECT_ROOT/out/raw/commits.csv"

    # Volver al PROJECT_ROOT antes de ejecutar
    cd "$PROJECT_ROOT"
    export WORKING_REPO="$TEST_TEMP_DIR/test-repo"

    # ACT: Ejecutar pre-commit
    run bash "$SCRIPT_DIR/pre-commit"

    # ASSERT: No debe haber violaciones
    [[ $status -eq 0 ]]
    [[ -f "$PROJECT_ROOT/out/reports/precommit-violations.txt" ]]
    grep -q "✓ Sin violaciones" <<< "$output"
}
