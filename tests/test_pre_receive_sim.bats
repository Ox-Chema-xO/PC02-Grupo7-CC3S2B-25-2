#!/usr/bin/env bats
# test_pre_receive_sim.bats
# Pruebas GREEN para pre-receive-sim - Sprint 1
# Metodología RGR: estos tests deben FALLAR (exit 0) cuando pre-receive-sim no existe

setup() {
    export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../src" && pwd)"
    export PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export TEST_TEMP_DIR="$(mktemp -d)"
    export HOOK_SCRIPT="$PROJECT_ROOT/git-hooks/pre-receive-sim"
}

teardown() {
    cd "$PROJECT_ROOT" 2>/dev/null || true
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"
    [[ -f "$PROJECT_ROOT/.env" ]] && rm -f "$PROJECT_ROOT/.env"
    [[ -d "$PROJECT_ROOT/out" ]] && rm -rf "$PROJECT_ROOT/out"
}

# PRUEBA EXIT CODE: Valida que pre-receive-sim retorna 1 cuando detecta violaciones de force-push en ramas protegidas
@test "pre-receive-sim retorna EXIT_POLICY_VIOLATION (1) cuando detecta force-push en rama protegida" {
    # ARRANGE: Crear repositorio con evidencia de force-push en reflog
    mkdir -p "$TEST_TEMP_DIR/repo-with-force"
    cd "$TEST_TEMP_DIR/repo-with-force"
    git init --quiet
    git config user.name "Test"
    git config user.email "test@test.com"

    echo "v1" > file.txt
    git add file.txt
    git commit -m "Initial commit" --quiet
    echo "v2" > file.txt
    git add file.txt
    git commit --amend -m "Amended commit (forced-update)" --quiet

    export WORKING_REPO="$TEST_TEMP_DIR/repo-with-force"
    export REPO_URL="$TEST_TEMP_DIR/repo-with-force"
    export PROTECTED_BRANCHES="main,master"

    # ACT: Ejecutar pre-receive-sim
    run bash "$HOOK_SCRIPT"

    # ASSERT: Verificar exit code 1 y mensaje de violación
    [[ $status -eq 1 ]]
    [[ "$output" =~ "violaciones que el servidor rechazaría" ]]
}

# PRUEBA COBERTURA: Valida que pre-receive-sim ejecuta todas las verificaciones y genera reporte completo
@test "pre-receive-sim ejecuta todas las verificaciones y genera reporte prereceive-violations.txt" {
    # ARRANGE: Crear repositorio completo y archivos CSV para todas las verificaciones
    mkdir -p "$TEST_TEMP_DIR/repo-complete"
    cd "$TEST_TEMP_DIR/repo-complete"
    git init --quiet
    git config user.name "Test"
    git config user.email "test@test.com"

    echo "test" > file.txt
    git add file.txt
    git commit -m "Commit inicial para pruebas" --quiet

    # Crear tag sin semver
    git tag "release-1.0"

    # Crear CSVs con violaciones
    mkdir -p "$PROJECT_ROOT/out/raw"

    # CSV de tags (violación: no sigue semver)
    cat > "$PROJECT_ROOT/out/raw/tags.csv" << 'EOF'
release-1.0|2025-01-01|Test|test@test.com
EOF

    # CSV de tag signatures (violación: unsigned)
    cat > "$PROJECT_ROOT/out/raw/tag-signatures.csv" << 'EOF'
release-1.0|unsigned|2025-01-01|Test
EOF

    # CSV de reflog (violación: rebase)
    cat > "$PROJECT_ROOT/out/raw/reflog.csv" << 'EOF'
abc123|HEAD@{0}|rebase: main
EOF

    export WORKING_REPO="$TEST_TEMP_DIR/repo-complete"
    export REPO_URL="$TEST_TEMP_DIR/repo-complete"
    export PROTECTED_BRANCHES="main"
    export REQUIRE_SIGNED_TAGS="true"

    run bash "$HOOK_SCRIPT"

    [[ -f "$PROJECT_ROOT/out/reports/prereceive-violations.txt" ]]
    [[ -s "$PROJECT_ROOT/out/reports/prereceive-violations.txt" ]]
    local report_content
    report_content=$(cat "$PROJECT_ROOT/out/reports/prereceive-violations.txt")
    [[ "$report_content" =~ "Violaciones detectadas" ]]
}

# PRUEBA CASO POSITIVO: Valida que pre-receive-sim acepta repositorio que cumple todas las políticas
@test "pre-receive-sim retorna EXIT_SUCCESS (0) cuando repositorio cumple todas las políticas" {
    # ARRANGE: Crear repositorio sin violaciones
    mkdir -p "$TEST_TEMP_DIR/repo-compliant"
    cd "$TEST_TEMP_DIR/repo-compliant"
    git init --quiet
    git config user.name "Test"
    git config user.email "test@test.com"

    # Commit descriptivo (cumple políticas)
    echo "feature" > feature.txt
    git add feature.txt
    git commit -m "Implementa nueva funcionalidad de autenticación con JWT" --quiet

    # Tag con semver correcto
    git tag -a "v1.0.0" -m "Release version 1.0.0"

    # Crear CSVs sin violaciones
    mkdir -p "$PROJECT_ROOT/out/raw"

    cat > "$PROJECT_ROOT/out/raw/tags.csv" << 'EOF'
v1.0.0|2025-01-01|Test|test@test.com
EOF

    cat > "$PROJECT_ROOT/out/raw/reflog.csv" << 'EOF'
abc123|HEAD@{0}|commit: Implementa nueva funcionalidad
EOF

    export WORKING_REPO="$TEST_TEMP_DIR/repo-compliant"
    export REPO_URL="$TEST_TEMP_DIR/repo-compliant"
    export PROTECTED_BRANCHES="main"
    export REQUIRE_SIGNED_TAGS="false"

    run bash "$HOOK_SCRIPT"

    [[ $status -eq 0 ]]
    [[ "$output" =~ "completadas exitosamente" || "$output" =~ "No se encontraron violaciones" ]]
}

# PRUEBA CASO NEGATIVO: Valida comportamiento robusto cuando archivos CSV no existen
@test "pre-receive-sim retorna EXIT_SUCCESS (0) cuando archivos CSV de auditoría no existen (edge case)" {
    # ARRANGE: Crear repositorio básico SIN archivos CSV
    mkdir -p "$TEST_TEMP_DIR/repo-minimal"
    cd "$TEST_TEMP_DIR/repo-minimal"
    git init --quiet
    git config user.name "Test"
    git config user.email "test@test.com"

    echo "test" > file.txt
    git add file.txt
    git commit -m "Commit inicial para testing" --quiet

    # NO crear CSVs (edge case)
    # NO crear directorio out/raw

    export WORKING_REPO="$TEST_TEMP_DIR/repo-minimal"
    export REPO_URL="$TEST_TEMP_DIR/repo-minimal"
    export PROTECTED_BRANCHES="develop"  # Rama que no existe
    export REQUIRE_SIGNED_TAGS="false"

    # ACT: Ejecutar pre-receive-sim
    run bash "$HOOK_SCRIPT"

    # ASSERT: Verificar que NO falla cuando faltan archivos (exit code 0)
    [[ $status -eq 0 ]]
    [[ "$output" =~ "No se encontraron" || "$output" =~ "completadas exitosamente" ]]
}
