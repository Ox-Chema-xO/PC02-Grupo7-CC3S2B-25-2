#!/usr/bin/env bats

# Pruebas de idempotencia para targets del Makefile
# Una operación es idempotente si ejecutarla múltiples veces tiene el mismo efecto que ejecutarla una vez.

setup() {
    export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export TEST_TEMP_DIR="$(mktemp -d)"

    cd "$PROJECT_ROOT"

    # Crear repositorio de prueba con violaciones conocidas
    mkdir -p "$TEST_TEMP_DIR/idempotency-repo"
    cd "$TEST_TEMP_DIR/idempotency-repo"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "initial content" > file.txt
    git add file.txt
    git commit -m "Agregar funcionalidad inicial" --quiet
    echo "some other content" > another.txt
    git add another.txt
    git commit -m "wip" --quiet
    cd "$PROJECT_ROOT"

    # Configurar .env para pruebas
    cat > "$PROJECT_ROOT/.env" << EOF
REPO_URL="$TEST_TEMP_DIR/idempotency-repo"
PROTECTED_BRANCHES="main"
REQUIRE_SIGNED_TAGS="false"
MIN_COMMIT_LENGTH="10"
MAX_COMMIT_LENGTH="72"
EOF
}

teardown() {
    cd "$PROJECT_ROOT" 2>/dev/null || true
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"
    [[ -d "$PROJECT_ROOT/out" ]] && rm -rf "$PROJECT_ROOT/out"
    [[ -d "$PROJECT_ROOT/dist" ]] && rm -rf "$PROJECT_ROOT/dist"
    [[ -f "$PROJECT_ROOT/.env" ]] && rm -f "$PROJECT_ROOT/.env"
}

@test "Idempotencia: make build puede ejecutarse múltiples veces" {
    # Arrange
    # (El entorno ya está configurado en setup())

    # Act
    run make build
    [ "$status" -eq 0 ]
    [ -d "$PROJECT_ROOT/out/raw" ]
    [ -d "$PROJECT_ROOT/out/reports" ]
    [ -f "$PROJECT_ROOT/out/audit-config.env" ]

    run make build

    # Assert
    [ "$status" -eq 0 ]
    [ -d "$PROJECT_ROOT/out/raw" ]
    [ -d "$PROJECT_ROOT/out/reports" ]
    [ -f "$PROJECT_ROOT/out/audit-config.env" ]
}

@test "Idempotencia: make run produce la misma salida en múltiples ejecuciones" {
    # Arrange
    # (El setup() crea un repositorio con commit "wip" que viola políticas)

    # Act
    run make run
    local first_status=$status

    local first_violations=0
    if [[ "$output" =~ ([0-9]+)\ violaciones\ encontradas ]]; then
        first_violations="${BASH_REMATCH[1]}"
    fi

    local first_checksum
    first_checksum=$(find "$PROJECT_ROOT/out/reports" -name "*-violations.txt" -type f -exec md5sum {} + 2>/dev/null | sort -k 2 | md5sum)

    run make run
    local second_status=$status

    local second_violations=0
    if [[ "$output" =~ ([0-9]+)\ violaciones\ encontradas ]]; then
        second_violations="${BASH_REMATCH[1]}"
    fi

    local second_checksum
    second_checksum=$(find "$PROJECT_ROOT/out/reports" -name "*-violations.txt" -type f -exec md5sum {} + 2>/dev/null | sort -k 2 | md5sum)

    # Assert
    [ "$first_status" -eq "$second_status" ]
    [ "$first_violations" -eq "$second_violations" ]
    [ "$first_checksum" = "$second_checksum" ]
}

@test "Idempotencia: make clean seguido de make build restaura el entorno" {
    # Arrange
    make build

    local first_checksum
    first_checksum=$(find "$PROJECT_ROOT/out" -type f -exec md5sum {} + | sort -k 2 | md5sum)

    # Act
    run make clean
    [ "$status" -eq 0 ]
    [ ! -d "$PROJECT_ROOT/out" ]
    [ ! -d "$PROJECT_ROOT/dist" ]

    run make build
    [ "$status" -eq 0 ]

    local second_checksum
    second_checksum=$(find "$PROJECT_ROOT/out" -type f -exec md5sum {} + | sort -k 2 | md5sum)

    # Assert
    [ "$first_checksum" = "$second_checksum" ]
}
