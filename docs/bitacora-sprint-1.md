# Bitácora Sprint 1

**Equipo:** Grupo 7 - CC3S2B 2025-2
**Duración:** 2 semanas

## Objetivo

Construir la base del sistema de auditoría Git: scripts que extraigan información de repositorios y validen el entorno antes de ejecutar.

## Lo que hicimos

### Infraestructura básica

Creamos 6 scripts modulares en `src/`:

1. **validate_environment.sh**: Verifica que existan las herramientas necesarias (git, jq, curl, grep, awk). También se valida que `REPO_URL` esté configurado.

2. **prepare_workspace.sh**: Prepara los directorios `out/raw/` y `out/reports/` donde se guardan los datos extraídos y los reportes de violaciones.

3. **setup_repository.sh**: Detecta si `REPO_URL` es local o remoto. Si es remoto, clona el repo a `/tmp`. Implementamos trap handlers para limpiar archivos temporales si algo falla.

4. **git-info-extractor.sh**: Extrae informacion del repositorio usando comandos git

5. **query-remote-policies.sh**: Consulta la GitHub API v3 para obtener políticas de protección de ramas.

6. **script_principal.sh**: Realiza la auditoria completa.

### Decisiones que tomamos

**CSV con pipe (|) como delimitador**: Los mensajes de commit tienen comas, así que usar `,` como separador rompía todo. Con `|` podemos hacer `cut -d'|' -f5` sin problemas.

**GitHub API v3**: Elegimos la API de GitHub para consultar las ramas protegidas en repo remotos.

**Trap handlers**: Aprendimos por las malas que repositorios clonados se quedaban en `/tmp` después de errores. Ahora usamos `trap cleanup EXIT INT TERM` en todos los scripts que crean recursos temporales.

**Logging a stderr**: Todos los logs van a stderr con `log() { echo "[script] $*" >&2; }`. Así separamos logs de datos y podemos hacer pipelines limpios.

## Testing

Escribimos 20 tests con BATS siguiendo patrón AAA:
- 4 tests para validación de entorno
- 4 tests para workspace
- 3 tests para setup de repositorio
- 3 tests para extracción Git
- 4 tests para políticas remotas
- 2 tests para flujo completo

## Resultados

El sistema extrae correctamente:
- Ramas locales y remotas
- Historial completo de commits en formato CSV parseable
- Tags con estado de firma GPG
- Reflog para análisis de operaciones
- Políticas de GitHub (protected branches)

Todo se guarda en `out/raw/` listo para el Sprint 2 donde implementaremos los hooks que validen políticas.

**Video:** https://drive.google.com/file/d/1fqYnsCZnfsgDeEsjv6wa4pGi-QOg0N5b/view
