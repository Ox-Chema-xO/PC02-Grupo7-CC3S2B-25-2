#!/usr/bin/env bats
# test_git_info_extractor.bats
# Prueba GREEN para git-info-extractor.sh
# Valida cobertura de funcionalidad y exit codes correctos

setup() {
    export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../src" && pwd)"
    export PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    export TEST_TEMP_DIR="$(mktemp -d)"

    mkdir -p "$PROJECT_ROOT/out/raw"

    # Crear repositorio
    mkdir -p "$TEST_TEMP_DIR/test-repo"
    cd "$TEST_TEMP_DIR/test-repo"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Crear varios commits
    echo "commit 1" > file1.txt
    git add file1.txt
    git commit -m "First commit in repository" --quiet
    echo "commit 2" > file2.txt
    git add file2.txt
    git commit -m "Second commit with changes" --quiet
    
    git tag -a v1.0 -m "Version 1.0 release"

    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="$TEST_TEMP_DIR/test-repo"
PROTECTED_BRANCHES="main"
REQUIRE_SIGNED_TAGS="false"
EOF
}

teardown() {
    cd "$PROJECT_ROOT" 2>/dev/null || true
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR" || true
    [[ -d "$PROJECT_ROOT/out" ]] && rm -rf "$PROJECT_ROOT/out" || true
    [[ -f "$PROJECT_ROOT/.env" ]] && rm -f "$PROJECT_ROOT/.env" || true
}

# PRUEBA COBERTURA: Valida extracción completa de información del repositorio. Verifica extracción de ramas, commits, tags, reflog
@test "git-info-extractor.sh extrae correctamente información de ramas, commits y tags" {
    # ARRANGE: Ya tenemos repositorio configurado en setup()

    run bash "$SCRIPT_DIR/git-info-extractor.sh" "$TEST_TEMP_DIR/test-repo"

    [[ $status -eq 0 ]]
    [[ -f "$PROJECT_ROOT/out/raw/local-branches.txt" ]]
    [[ -f "$PROJECT_ROOT/out/raw/remote-branches.txt" ]]
    [[ -f "$PROJECT_ROOT/out/raw/commits.csv" ]]
    [[ -f "$PROJECT_ROOT/out/raw/commit-graph.txt" ]]
    [[ -f "$PROJECT_ROOT/out/raw/tags.csv" ]]
    [[ -f "$PROJECT_ROOT/out/raw/tag-signatures.csv" ]]
    [[ -f "$PROJECT_ROOT/out/raw/reflog.csv" ]]
    grep -q "First commit in repository" "$PROJECT_ROOT/out/raw/commits.csv"
    grep -q "Second commit with changes" "$PROJECT_ROOT/out/raw/commits.csv"
}

# PRUEBA COBERTURA: Valida detección de tags y firmas. Verifica procesamiento de tags firmados/no firmados
@test "git-info-extractor.sh detecta correctamente tags y su estado de firma" {
    # ARRANGE: Ya tenemos tag v1.0 en setup()

    run bash "$SCRIPT_DIR/git-info-extractor.sh" "$TEST_TEMP_DIR/test-repo"

    [[ -f "$PROJECT_ROOT/out/raw/tags.csv" ]]
    grep -q "v1.0" "$PROJECT_ROOT/out/raw/tags.csv"
    [[ -f "$PROJECT_ROOT/out/raw/tag-signatures.csv" ]]
    grep -q "v1.0|unsigned" "$PROJECT_ROOT/out/raw/tag-signatures.csv"
}

# PRUEBA EXIT CODE: Valida manejo de repositorio sin parámetro usando .env. Verifica que falla con exit 1 cuando falta repositorio
@test "git-info-extractor.sh retorna EXIT_GENERIC (1) cuando no se especifica repositorio" {
    rm -f "$PROJECT_ROOT/.env"

    run bash "$SCRIPT_DIR/git-info-extractor.sh"

    [[ $status -eq 1 ]]
    [[ "$output" =~ "Debe especificar el repositorio" ]]
}
