# Bitácora Sprint 2

**Equipo:** Grupo 7 - CC3S2B 2025-2

## Objetivo

Implementar hooks que validen políticas de forma retrospectiva, analizando el historial sin tocar el repositorio.

## Lo que hicimos

### 3 Hooks de validación

**1. pre-commit** (`git-hooks/pre-commit`)

Detecta problemas de calidad en historial de commits desde `commits.csv`
- Archivos temporales (`.tmp`, `.log`, `.swp`, `.bak`) usando `git diff-tree` sobre cada commit
- Scripts sin shebang `#!/bin/bash`
- Errores de sintaxis bash con `bash -n`

Finalmente se genera `precommit-violations.txt`.

**2. commit-msg** (`git-hooks/commit-msg`)

Valida mensajes de commit según reglas configurables:
- Longitud entre 10-72 caracteres (`MIN_COMMIT_LENGTH`, `MAX_COMMIT_LENGTH`)
- Formato: mayúscula inicial, sin punto final
- Prefijos válidos: `feat:`, `fix:`, `docs:`, `refactor:`, etc.

Finalmente se genera `precommit-violations.txt`.

**3. pre-receive-sim** (`git-hooks/pre-receive-sim`)

Simula lo que un servidor Git rechazaría usando `reflog.csv`, `tags.csv`, `tag-signatures.csv`
- Force-push en ramas protegidas (detecta `forced-update`, `rebase`, `reset --hard` en reflog)
- Tags sin firma GPG cuando `REQUIRE_SIGNED_TAGS=true`
- Tags que no siguen semver `^v[0-9]+\.[0-9]+\.[0-9]+$`

Finalmente se genera `prereceive-violations.txt`.

### Script orquestador

**policy-checker.sh**: Ejecuta los 3 hooks secuencialmente.

## Decisiones que tomamos

**Análisis retrospectivo**: No hacemos checkout ni modificamos nada. Leemos CSVs generados en Sprint 1 y analizamos con comandos read-only de git (`git show`, `git diff-tree`). Es más seguro y funciona en repos de solo lectura.

**Detección de force-push vía reflog**: En lugar de comparar hashes (que no captura todo), parseamos reflog buscando patrones como `"reset.*--hard"` y `"forced-update"`.

## Problemas encontrados

**Simular force-push en tests**: No podíamos hacer force-push real en tests por lo cual creamos repos temporales con reflog artificial (`echo "... forced-update" > .git/logs/refs/heads/main`).

## Testing (TDD)

Seguimos ciclo RED--GREEN:
1. Escribimos test que falla (hook no existe)
2. Implementamos hook mínimo
3. Test pasa

12 tests nuevos:
- 4 para pre-commit (archivos temp, shebangs, sintaxis)
- 4 para commit-msg (longitud, formato, prefijos, prohibidos)
- 4 para pre-receive-sim (force-push, tags, semver, reescritura)

## Resultados

Probamos en repos remotos y locales, y detectamos:
- Commits con archivos `.swp` olvidados
- Commits genéricos
- Tags sin firma GPG
- Archivos `.log` subidos

Los reportes se guardan en `out/reports/`

## Mejoras adicionales

- Simplificamos Makefile delegando lógica a scripts bash
- Agregamos backup de `.env` en tests

**Video:** https://drive.google.com/file/d/1Zcv8O-uDKIOaHMF2lkUxyB15OZWzdv-E/view
