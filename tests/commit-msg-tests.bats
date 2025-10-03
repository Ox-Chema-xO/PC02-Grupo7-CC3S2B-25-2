#!/usr/bin/env bats

# Tests para el hook commit-msg
# Verifica la validación de mensajes de commit

setup() {
    # Configurar entorno de pruebas
    export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
    export SCRIPT_DIR="$PROJECT_ROOT/git-hooks"

    # Crear directorios de prueba
    mkdir -p "$PROJECT_ROOT/out/raw"
    mkdir -p "$PROJECT_ROOT/out/reports"

    # Cargar funciones del script commit-msg
    source "$PROJECT_ROOT/git-hooks/commit-msg"
}

teardown() {
    # Limpiar archivos de prueba
    rm -f "$PROJECT_ROOT/out/raw/commits.csv"
    rm -f "$PROJECT_ROOT/out/reports/commit-msg-violations.txt"
}

@test "Mensaje de commit válido con prefijo correcto pasa validación" {
    # Arrange: Preparar archivo de commits con mensaje válido
    echo "abc123|Test Author|test@example.com|2024-01-01|Agregar nueva funcionalidad de auditoría" > "$PROJECT_ROOT/out/raw/commits.csv"

    # Act: Ejecutar verificación
    run verify_commit_messages

    # Assert: Debe ser exitoso (código de salida 0)
    [ "$status" -eq 0 ]
}

@test "Mensaje corto dispara violación de longitud mínima" {
    # Arrange: Preparar archivo de commits con mensaje muy corto (< 10 caracteres)
    echo "def456|Test Author|test@example.com|2024-01-01|fix bug" > "$PROJECT_ROOT/out/raw/commits.csv"

    # Act: Ejecutar verificación
    run verify_commit_messages

    # Assert: Debe fallar (código de salida 1) y generar reporte
    [ "$status" -eq 1 ]
    [ -f "$PROJECT_ROOT/out/reports/commit-msg-violations.txt" ]
    grep -q "Mensaje muy corto" "$PROJECT_ROOT/out/reports/commit-msg-violations.txt"
}

@test "Mensaje genérico prohibido es detectado como violación" {
    # Arrange: Preparar archivo de commits con mensaje genérico prohibido
    echo "ghi789|Test Author|test@example.com|2024-01-01|wip" > "$PROJECT_ROOT/out/raw/commits.csv"

    # Act: Ejecutar verificación
    run verify_commit_messages

    # Assert: Debe fallar y detectar patrón prohibido
    [ "$status" -eq 1 ]
    [ -f "$PROJECT_ROOT/out/reports/commit-msg-violations.txt" ]
    grep -q "Mensaje genérico prohibido" "$PROJECT_ROOT/out/reports/commit-msg-violations.txt"
}

@test "Mensaje sin prefijo válido dispara violación de formato" {
    # Arrange: Preparar archivo de commits con mensaje sin prefijo válido
    echo "jkl012|Test Author|test@example.com|2024-01-01|este es un commit sin prefijo válido" > "$PROJECT_ROOT/out/raw/commits.csv"

    # Act: Ejecutar verificación
    run verify_commit_messages

    # Assert: Debe fallar y detectar falta de prefijo
    [ "$status" -eq 1 ]
    [ -f "$PROJECT_ROOT/out/reports/commit-msg-violations.txt" ]
    grep -q "sin prefijo válido" "$PROJECT_ROOT/out/reports/commit-msg-violations.txt"
}
