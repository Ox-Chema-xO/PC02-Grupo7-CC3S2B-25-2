# PC02 – Sistema de Auditoría de Políticas Git con Validación Retrospectiva

## Descripción general

Este proyecto implementa un **sistema de auditoría automatizada** para validar políticas de seguridad y buenas prácticas en repositorios Git mediante análisis retrospectivo del historial. El enfoque es modular y extensible, permitiendo:

- Validación automática del entorno de ejecución.
- Extracción exhaustiva de información del repositorio (ramas, commits, tags, firmas, reflog).
- Consulta de políticas de protección en plataformas remotas (GitHub).
- **Verificación retrospectiva de políticas mediante Git hooks**.
- Simulación de políticas del servidor (pre-receive).
- Generación de reportes detallados de auditoría y violaciones.

El sistema sigue principios de **scripting robusto** con manejo de errores, logging estructurado, limpieza automática de recursos y **metodología TDD** (Test-Driven Development).

### Tecnologías y herramientas

- **Bash scripting avanzado** (trap handlers, funciones modulares, heredocs).
- **Git** (análisis de historial, ramas, tags, firmas, reflog).
- **GitHub API** (consulta de políticas de protección).
- **Git Hooks** (pre-commit, commit-msg, pre-receive-sim).
- **Herramientas Unix**: `jq`, `curl`, `grep`, `awk`, `sed`, `cut`, `sort`, `uniq`.
- **Testing**: `bats` (Bash Automated Testing System).
- **Automatización**: `Makefile`.

---

## Estructura del proyecto

```text
PC02-Grupo7-CC3S2B-25-2/
├── Makefile                          # Reglas de construcción y ejecución
├── README.md                         # Documentación del proyecto
├── .env.example                      # Plantilla de configuración
├── src/
│   ├── script_principal.sh           # Script orquestador principal
│   ├── utils.sh                      # Funciones de apoyo y logging
│   ├── validate_environment.sh       # Validación de dependencias
│   ├── prepare_workspace.sh          # Preparación de directorios
│   ├── setup_repository.sh           # Configuración de acceso al repo
│   ├── git-info-extractor.sh         # Extracción de información Git
│   ├── query-remote-policies.sh      # Consulta de políticas remotas
│   └── policy-checker.sh             # Orquestador de hooks de políticas
├── git-hooks/
│   ├── pre-commit                    # Validación de archivos temporales, shebangs, sintaxis
│   ├── commit-msg                    # Validación de mensajes de commit
│   └── pre-receive-sim               # Simulación de políticas del servidor
├── tests/
│   ├── test_validate_environment.bats
│   ├── test_script_principal.bats
│   ├── test_git_info_extractor.bats
│   ├── test_prepare_workspace.bats
│   ├── test_query_remote_policies.bats
│   ├── test_setup_repository.bats
│   ├── test_pre_commit.bats
│   ├── commit-msg-tests.bats
│   └── test_pre_receive_sim.bats
└── out/
    ├── raw/                          # Datos extraídos en CSV/texto
    │   ├── branches.csv
    │   ├── commits.csv
    │   ├── commit-graph.txt
    │   ├── signed-tags.txt
    │   ├── reflog.txt
    │   └── remote-branch-policies.csv
    ├── reports/                      # Reportes de violaciones
    │   ├── precommit-violations.txt
    │   ├── commitmsg-violations.txt
    │   └── prereceive-violations.txt
    └── audit-config.env              # Configuración de la auditoría
```

---

## Bitácora del Sprint 1

### Objetivo

Establecer los **componentes fundamentales** del sistema de auditoría con arquitectura modular y preparar la base para validación de políticas.

### Logros

- **Arquitectura modular**: Scripts independientes con responsabilidades únicas.
- **Validación de entorno**: Verificación automática de dependencias y variables.
- **Extracción Git completa**: Ramas, commits, tags firmados, reflog y grafo.
- **Integración con GitHub API**: Consulta de políticas de protección de ramas.
- **Sistema de logging**: Registro estructurado de eventos y errores.
- **Manejo robusto de errores**: Códigos de salida estandarizados y trap handlers.
- **Makefile mejorado**: Comando `help` con colores y descripción de targets.

### Dificultades

- Manejo de repositorios locales vs remotos (clonado seguro).
- Parseo de respuestas JSON de la API de GitHub.
- Validación de patrones con comodines en nombres de ramas.
- Limpieza automática de recursos temporales.

---

## Guía de ejecución (Sprint 1)

### Requisitos previos

- Sistema Linux/Mac con **bash 4.0+**.
- Dependencias instaladas: `git`, `jq`, `curl`, `grep`, `awk`, `sed`, `cut`, `sort`, `uniq`.
- Token de GitHub (opcional, para consultas API sin límite de rate).

### Variables de entorno

```bash
export REPO_URL="https://github.com/usuario/repositorio.git"  # Obligatorio
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxx"                        # Opcional
export PROTECTED_BRANCHES="main,develop,release/*"             # Opcional
export MIN_COMMIT_MESSAGE_LENGTH="10"                          # Opcional
```

### Pasos

1. **Clonar repositorio**

   ```bash
   git clone <url-del-proyecto>
   cd proyecto-auditoria-git
   ```

2. **Verificar dependencias**

   ```bash
   make help
   ```

3. **Ejecutar auditoría completa**

   ```bash
   ./script_principal.sh
   ```

4. **Revisar resultados**

   ```bash
   cat out/audit-report.txt
   ls -la out/raw/
   ```

---

## Funcionalidades implementadas

### script_principal.sh

- Orquestación del flujo completo de auditoría.
- Carga de módulos con manejo de errores.
- Generación de reporte consolidado con metadatos.
- Códigos de salida estandarizados (0: éxito, 1: error crítico, 2: advertencias).

### validate_environment.sh

- Validación de comandos críticos del sistema.
- Verificación de variables de entorno obligatorias.
- Validación de formato de parámetros numéricos.

### setup_repository.sh

- Detección inteligente de repositorios locales/remotos.
- Clonado seguro con validación de URL.
- Trap handlers para limpieza de recursos temporales.

### git-info-extractor.sh

- Extracción de ramas locales y remotas.
- Registro de commits en CSV (hash, autor, email, fecha, mensaje).
- Generación de grafo visual de historial.
- Verificación de firmas GPG en tags.
- Dump completo del reflog.

### query-remote-policies.sh

- Consulta a GitHub API v3 para políticas de protección.
- Soporte para múltiples ramas protegidas.
- Autenticación con token (evita rate limiting).
- Exportación estructurada en CSV.

---

## Checklist de completitud

- [x] Script principal `policy-auditor.sh` funcional.
- [x] Validación automática de entorno y dependencias.
- [x] Preparación de espacio de trabajo con configuración.
- [x] Configuración de acceso a repositorios locales/remotos.
- [x] Extracción completa de información Git.
- [x] Consulta de políticas de protección en GitHub.
- [x] Sistema de logging estructurado.
- [x] Manejo robusto de errores con trap handlers.
- [x] Generación de reportes de auditoría.
- [x] Suite completa de pruebas BATS (20 tests en GREEN).
- [x] Cobertura de tests: validación de entorno, extracción Git, workspace, políticas remotas.
- [x] Estructura AAA en tests con setup/teardown automático.
- [x] Validación de EXIT CODES (0, 1, 5) en todos los componentes.

### Testing (TDD)

Suite completa de pruebas BATS siguiendo metodología TDD:

**Archivos de prueba:**
- `tests/test_validate_environment.bats` (4 tests)
- `tests/test_script_principal.bats` (2 tests)
- `tests/test_git_info_extractor.bats` (3 tests)
- `tests/test_prepare_workspace.bats` (4 tests)
- `tests/test_query_remote_policies.bats` (4 tests)
- `tests/test_setup_repository.bats` (3 tests)

**Cobertura:**
- Flujo completo del sistema de auditoría
- Validación de herramientas requeridas
- Extracción de ramas, commits, tags y reflog
- Generación de archivos CSV y reportes
- Manejo de errores y casos edge

---

## Bitácora del Sprint 2

### Objetivo

Implementar **validación de políticas mediante Git hooks** con verificaciones retrospectivas del historial y simulación de políticas de servidor.

### Logros

- **Git Hooks implementados:**
  - `pre-commit`: Validación de archivos temporales, shebangs y sintaxis bash
  - `commit-msg`: Validación de formato, longitud y prefijos de mensajes
  - `pre-receive-sim`: Simulación de políticas del servidor (ramas protegidas, tags firmados, reescritura de historial)

- **Script orquestador**: `policy-checker.sh` para ejecución centralizada de hooks
- **Simplificación del Makefile**: Delegación de lógica a scripts bash
- **Suite de pruebas BATS**: 12 tests nuevos siguiendo metodología TDD (RED → GREEN)
- **Integración completa**: `script_principal.sh` llama a `policy-checker.sh`

### Implementaciones clave

#### Hook pre-commit (`git-hooks/pre-commit`)

**Verificaciones retrospectivas:**
- `check_temporary_files()`: Detecta archivos `.tmp`, `.log`, `.swp`, `.bak` en historial
- `check_script_shebangs()`: Valida presencia de shebang `#!/bin/bash` en scripts `.sh`
- `check_bash_syntax()`: Verifica sintaxis con `bash -n` en scripts del HEAD

**Características:**
- Análisis de commits usando `git diff-tree`
- Generación de `precommit-violations.txt`
- Configuración vía variables de entorno

#### Hook commit-msg (`git-hooks/commit-msg`)

**Validaciones de mensajes:**
1. `check_commit_length()`: Longitud entre MIN_COMMIT_LENGTH (10) y MAX_COMMIT_LENGTH (72)
2. `check_commit_format()`: Mayúscula inicial, sin punto final
3. `check_required_prefix()`: Prefijos autorizados (feat, fix, docs, etc.) o conventional commits
4. `check_forbidden_patterns()`: Detecta mensajes genéricos (wip, fix, test, update)

**Características:**
- Lectura de mensajes desde archivo `commits.csv`
- Generación de `commitmsg-violations.txt`
- Exit code 1 si hay violaciones

#### Hook pre-receive-sim (`git-hooks/pre-receive-sim`)

**Simulación de políticas del servidor:**
1. `check_protected_branches()`: Detecta force-push en ramas protegidas
2. `check_tag_signatures()`: Valida tags firmados cuando `REQUIRE_SIGNED_TAGS=true`
3. `check_tag_naming()`: Valida nomenclatura semver (vX.Y.Z)
4. `check_history_rewriting()`: Detecta operaciones peligrosas en reflog

**Características:**
- Análisis de `branches.csv`, `signed-tags.txt` y `reflog.txt`
- Generación de `prereceive-violations.txt`
- Exit code 1 si el servidor rechazaría el push

#### Script orquestador (`src/policy-checker.sh`)

**Funcionalidad:**
- Ejecuta secuencialmente todos los hooks de verificación
- Carga automática de variables desde `.env`
- Validación de existencia de repositorio
- Sistema de logging integrado
- Manejo de exit codes correcto

### Mejoras al sistema

**Makefile actualizado:**
- Target `tools`: Llama a `validate_environment.sh`
- Target `build`: Llama a `prepare_workspace.sh`
- Eliminación de lógica redundante

**Integración completa:**
- `script_principal.sh` → `check_policies()` → `policy-checker.sh` → hooks individuales

### Testing (TDD - Sprint 2)

12 tests nuevos siguiendo ciclo RED → GREEN:

**Archivos de prueba:**
- `tests/test_pre_commit.bats` (4 tests)
- `tests/commit-msg-tests.bats` (4 tests)
- `tests/test_pre_receive_sim.bats` (4 tests)

**Metodología:**
1. Fase RED: Tests definidos sin implementación
2. Fase GREEN: Implementación de hooks

**Cobertura:**
- Detección de archivos temporales en historial
- Validación de shebangs en scripts
- Verificación de sintaxis bash
- Validación de mensajes de commit (longitud, formato, prefijos)
- Detección de mensajes genéricos prohibidos
- Manejo de casos edge

## Checklist de completitud Sprint 2

- [x] Hook pre-commit implementado y probado
- [x] Hook commit-msg implementado y probado
- [x] Hook pre-receive-sim implementado y probado
- [x] Script orquestador policy-checker.sh funcional
- [x] Suite de pruebas BATS (12 tests en GREEN)
- [x] Integración con script_principal.sh
- [x] Simplificación del Makefile
- [x] Documentación de hooks y validaciones
- [x] Manejo de exit codes estandarizado
- [x] Generación de reportes de violaciones

---

## Videos de sprints
- **Sprint 1**: https://drive.google.com/file/d/1fqYnsCZnfsgDeEsjv6wa4pGi-QOg0N5b/view?usp=sharing
- **Sprint 2**: https://drive.google.com/file/d/1Zcv8O-uDKIOaHMF2lkUxyB15OZWzdv-E/view?usp=sharing
