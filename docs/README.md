# Proyecto 8 - Scanner de Políticas Git

## Descripción

Sistema de auditoría automatizada para validar políticas de seguridad y buenas prácticas en repositorios Git mediante análisis retrospectivo del historial.

**Validaciones:**
- Ramas protegidas y force-push
- Mensajes de commit (formato, longitud, prefijos)
- Tags firmados con GPG
- Archivos temporales en historial
- Shebangs y sintaxis bash

---

## Inicio Rápido

```bash
# Clonar
git clone https://github.com/Ox-Chema-xO/PC02-Grupo7-CC3S2B-25-2.git
cd PC02-Grupo7-CC3S2B-25-2

# Configurar
cp .env.example .env
vim .env  # Configurar REPO_URL obligatorio

# Ejecutar
make build
make run
```

---

## Variables de Entorno

| Variable | Tipo | Efecto Observable | Ejemplo |
|----------|------|-------------------|---------|
| `REPO_URL` | Obligatorio | URL o ruta del repositorio a auditar | `https://github.com/user/repo` |
| `GITHUB_TOKEN` | Opcional | Token para API (evita rate limit 60→5000 req/h) | `ghp_xxxxxxxxxxxx` |
| `PROTECTED_BRANCHES` | Opcional | Ramas a validar force-push | `main,develop,release/*` |
| `REQUIRE_SIGNED_TAGS` | Opcional | Requiere tags firmados GPG | `true` o `false` |
| `MIN_COMMIT_LENGTH` | Opcional | Longitud mínima mensaje commit | `10` |
| `MAX_COMMIT_LENGTH` | Opcional | Longitud máxima mensaje commit | `72` |

**Valores por defecto:**
```bash
PROTECTED_BRANCHES="main,develop"
REQUIRE_SIGNED_TAGS="false"
MIN_COMMIT_LENGTH="10"
MAX_COMMIT_LENGTH="72"
```

---

## Comandos

| Comando | Descripción |
|---------|-------------|
| `make tools` | Verificar dependencias del sistema (git, jq, curl, bats) |
| `make build` | Preparar workspace (crear out/, dist/, validar entorno) |
| `make run` | Ejecutar auditoría completa (genera archivos en out/) |
| `make test` | Ejecutar suite de pruebas BATS (32 tests) |
| `make pack` | Empaquetar distribución en dist/ |
| `make clean` | Limpiar artefactos (borra out/ y dist/) |
| `make help` | Mostrar ayuda de targets |

---

## Arquitectura

### Scripts de Auditoría (src/)
- `script_principal.sh` - Orquestador principal
- `validate_environment.sh` - Validación de dependencias
- `prepare_workspace.sh` - Creación de directorios
- `setup_repository.sh` - Acceso al repositorio
- `git-info-extractor.sh` - Extracción de información Git
- `query-remote-policies.sh` - Consulta GitHub API
- `policy-checker.sh` - Orquestador de hooks
- `utils.sh` - Funciones compartidas

### Git Hooks (git-hooks/)
- `pre-commit` - Archivos temporales, shebangs, sintaxis
- `commit-msg` - Formato, longitud, prefijos de mensajes
- `pre-receive-sim` - Políticas del servidor (ramas, tags, reescritura)

### Tests (tests/)
9 archivos BATS, 32+ tests con metodología TDD (RED → GREEN)

---

## Políticas Validadas

| Política | Validaciones | Hook |
|----------|-------------|------|
| **Ramas Protegidas** | Force-push vía reflog, estado en GitHub API | `pre-receive-sim` |
| **Mensajes de Commit** | Longitud 10-72 chars, mayúscula inicial, sin punto final, prefijos válidos (feat/fix/docs/refactor/test/chore), prohibidos (wip/fix/test/update) | `commit-msg` |
| **Tags Firmados** | Firma GPG cuando `REQUIRE_SIGNED_TAGS=true`, nomenclatura semver (vX.Y.Z) | `pre-receive-sim` |
| **Archivos Temporales** | `.tmp`, `.log`, `.swp`, `.bak`, `~`, `#...#` | `pre-commit` |
| **Calidad de Scripts** | Shebang `#!/bin/bash`, sintaxis bash válida | `pre-commit` |

---

## Salidas Generadas

### out/raw/ - Datos Extraídos
- `commits.csv` - Hash, autor, email, fecha, mensaje (CSV pipe)
- `local-branches.txt` - Ramas locales
- `remote-branches.txt` - Referencias remotas
- `tags.csv` - Tags con autor y fecha
- `tag-signatures.csv` - Estado de firma (signed/unsigned)
- `reflog.csv` - Historial de operaciones Git
- `remote-branch-policies.csv` - Políticas GitHub

### out/reports/ - Reportes
- `audit-summary.txt` - Resumen ejecutivo
- `precommit-violations.txt` - Violaciones pre-commit
- `commit-msg-violations.txt` - Violaciones mensajes
- `prereceive-violations.txt` - Violaciones servidor

### dist/ - Distribución
- `repository-analyzer.tar.gz` - Paquete comprimido
- `repository-analyzer.tar.gz.sha256` - Hash verificación

**Ver detalles completos:** [contrato-salidas.md](contrato-salidas.md)

---

## Códigos de Salida

| Código | Significado | Acción |
|--------|-------------|--------|
| `0` | Auditoría exitosa sin violaciones | Continuar |
| `1` | Violaciones detectadas | Revisar `out/reports/` |
| `5` | Error de configuración | Verificar `.env` |

```bash
make run
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] && echo "✓ Sin violaciones" || cat out/reports/*-violations.txt
```

---

## Validación Rápida

```bash
# Verificar ejecución
test -f out/audit-config.env && echo "✓ Ejecutado" || echo "✗ No ejecutado"

# Contar datos
wc -l out/raw/commits.csv  # Commits analizados
cat out/raw/local-branches.txt  # Ramas locales

# Buscar violaciones
grep -h "\[" out/reports/*-violations.txt 2>/dev/null | wc -l
grep "Force-push" out/reports/prereceive-violations.txt
grep "\[PROHIBIDO\]" out/reports/commit-msg-violations.txt

# Tags sin firma
grep "unsigned" out/raw/tag-signatures.csv | cut -d'|' -f1
```

---

## Casos de Uso

### Repositorio Remoto
```bash
export REPO_URL="https://github.com/usuario/proyecto.git"
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
make run
```

### Repositorio Local
```bash
export REPO_URL="/home/user/mi-proyecto"
export REQUIRE_SIGNED_TAGS="true"
make run
```

---

## Solución de Problemas

### Error: "No se encontró archivo .env"
```bash
cp .env.example .env
vim .env  # Configurar REPO_URL
```

### Dependencias faltantes
```bash
# Ubuntu/Debian
sudo apt-get install git jq curl bats

# macOS
brew install git jq curl bats-core
```

### Rate limit GitHub API
```bash
# Configurar token en .env
GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# Verificar límite
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit
```

---

## Documentación Adicional

- **[Bitácora Sprint 1](bitacora-sprint-1.md)** - Infraestructura base, extracción Git
- **[Bitácora Sprint 2](bitacora-sprint-2.md)** - Hooks, validación de políticas
- **[Contrato de Salidas](contrato-salidas.md)** - Especificación completa de archivos generados


---

## Videos

- **Sprint 1**: https://drive.google.com/file/d/1fqYnsCZnfsgDeEsjv6wa4pGi-QOg0N5b/view
- **Sprint 2**: https://drive.google.com/file/d/1Zcv8O-uDKIOaHMF2lkUxyB15OZWzdv-E/view

---

## Equipo 7

- Aaron Flores Alberca
- Diego Delgado
- Leonardo Chacón Roque
