# Contrato de Salidas - Scanner de Políticas Git

**Versión:** 1.0.0
**Proyecto:** Scanner de Políticas de Ramas y Tags Firmadas
**Equipo:** Grupo 7

---

## Estructura de Directorios

```
out/
├── audit-config.env              # Configuración de auditoría
├── raw/                          # Datos extraídos
│   ├── local-branches.txt
│   ├── remote-branches.txt
│   ├── commit-graph.txt
│   ├── commits.csv
│   ├── tags.csv
│   ├── tag-signatures.csv
│   ├── reflog.csv
│   └── remote-branch-policies.csv
├── reports/                      # Reportes de violaciones
│   ├── audit-summary.txt
│   ├── precommit-violations.txt
│   ├── commit-msg-violations.txt
│   └── prereceive-violations.txt
└── processed/                    # Reservado para datos procesados

dist/
├── repository-analyzer.tar    # Paquete de distribución en tar
└── repository-analyzer.tar.gz  # Paquete de distribución en tar.gz
```

---

## Archivos Generados

### Configuración

| Archivo | Formato | Contenido | Validación |
|---------|---------|-----------|------------|
| `audit-config.env` | KEY=VALUE | Variables de auditoría (REPO_URL, PROTECTED_BRANCHES, etc.) | `test -f out/audit-config.env` |

---

### Datos Extraídos (out/raw/)

| Archivo | Formato | Estructura | Ejemplo | Validación |
|---------|---------|------------|---------|------------|
| `local-branches.txt` | Texto | Una rama por línea | `main` | `wc -l out/raw/local-branches.txt` |
| `remote-branches.txt` | Texto | Una referencia por línea | `origin/develop` | `cat out/raw/remote-branches.txt` |
| `commits.csv` | CSV pipe | hash\|autor\|email\|fecha\|mensaje | `abc123...\|user\|email\|2025-01-01\|feat: mensaje` | `wc -l out/raw/commits.csv` |
| `commit-graph.txt` | Texto | Grafo ASCII de Git | `* abc123 feat: mensaje` | `head out/raw/commit-graph.txt` |
| `tags.csv` | CSV pipe | tag\|fecha\|autor\|email | `v1.0.0\|2025-01-01\|user\|email` | `cat out/raw/tags.csv` |
| `tag-signatures.csv` | CSV pipe | tag\|signed/unsigned\|fecha\|autor | `v1.0.0\|signed\|2025-01-01\|user` | `grep "unsigned" out/raw/tag-signatures.csv` |
| `reflog.csv` | CSV pipe | hash\|ref\|operación\|fecha | `abc123\|HEAD@{0}\|commit\|2025-01-01` | `grep "forced-update" out/raw/reflog.csv` |
| `remote-branch-policies.csv` | CSV pipe | rama\|estado\|detalles | `main\|protected\|details` | `grep "not_protected" out/raw/remote-branch-policies.csv` |

---

### Reportes (out/reports/)

| Archivo | Contenido | Categorías | Validación |
|---------|-----------|------------|------------|
| `audit-summary.txt` | Resumen ejecutivo de auditoría | Fecha, versión, archivos generados, configuración | `cat out/reports/audit-summary.txt` |
| `precommit-violations.txt` | Violaciones de pre-commit | [ARCHIVOS TEMPORALES], [SHEBANGS], [SINTAXIS] | `grep "\[" out/reports/precommit-violations.txt` |
| `commit-msg-violations.txt` | Violaciones de mensajes | [LONGITUD], [FORMATO], [PREFIJO], [PROHIBIDO] | `grep "Total violaciones" out/reports/commit-msg-violations.txt` |
| `prereceive-violations.txt` | Violaciones de servidor | [RAMAS PROTEGIDAS], [TAGS FIRMADOS], [NOMENCLATURA], [REESCRITURA] | `grep "Force-push" out/reports/prereceive-violations.txt` |

**Estructura de reportes de violaciones:**
```
# Violaciones detectadas por verificador <hook>
# Fecha: <timestamp>

[CATEGORÍA] Descripción (commit: hash, detalles)
...
```

---

### Distribución (dist/)

| Archivo | Formato | Contenido | Generación | Validación |
|---------|---------|-----------|------------|------------|
| `repository-analyzer.tar` | TAR | src/, tests/, git-hooks/, Makefile, README.md, .env.example | `make pack` | `tar -tzf dist/repository-analyzer.tar \| head` |
| `repository-analyzer.tar.gz` | TAR.GZ | src/, tests/, git-hooks/, Makefile, README.md, .env.example | `make pack` | `tar -tzf dist/repository-analyzer.tar.gz \| head` |

---

## Comandos de Validación Rápida

### Verificación Completa
```bash
# Verificar ejecución de auditoría
test -f out/audit-config.env && echo "Auditoría ejecutada" || echo "No ejecutada"

# Contar archivos generados
ls out/raw/*.{txt,csv} 2>/dev/null | wc -l  # Esperado: 8 archivos
ls out/reports/*.txt 2>/dev/null | wc -l    # Esperado: 3-4 archivos
```

### Análisis de Datos
```bash
# Commits analizados
wc -l out/raw/commits.csv

# Ramas locales
cat out/raw/local-branches.txt

# Tags sin firma
grep "unsigned" out/raw/tag-signatures.csv | cut -d'|' -f1

# Ramas sin protección
grep "not_protected" out/raw/remote-branch-policies.csv | cut -d'|' -f1
```

### Búsqueda de Violaciones
```bash
# Total de violaciones
grep -h "\[" out/reports/*-violations.txt 2>/dev/null | grep -v "^#" | wc -l

# Violaciones por hook
grep -c "\[" out/reports/precommit-violations.txt 2>/dev/null || echo "0"
grep "Total violaciones:" out/reports/commit-msg-violations.txt 2>/dev/null
grep -c "\[" out/reports/prereceive-violations.txt 2>/dev/null || echo "0"

# Force-push detectados
grep "Force-push" out/reports/prereceive-violations.txt

# Mensajes genéricos
grep "\[PROHIBIDO\]" out/reports/commit-msg-violations.txt
```


### Validación de Integridad
```bash
# Validar delimitador pipe
head -5 out/raw/commits.csv | grep -q "|" && echo "CSV válido" || echo "Sin delimitador"

# Validar hashes (40 caracteres hex)
cut -d'|' -f1 out/raw/commits.csv | grep -E "^[a-f0-9]{40}$" | wc -l
```

---

## Checklist de Validación Post-Ejecución

Después de ejecutar `make run`, verificar:

**Configuración:**
- [ ] `out/audit-config.env` existe y contiene variables

**Datos Extraídos (out/raw/):**
- [ ] `local-branches.txt` contiene al menos 1 rama
- [ ] `commits.csv` contiene commits (formato: hash|autor|email|fecha|mensaje)
- [ ] `commit-graph.txt` muestra grafo visual
- [ ] `reflog.csv` contiene historial de operaciones
- [ ] `remote-branch-policies.csv` existe (puede tener "# Sin token")
- [ ] Archivos CSV usan delimitador `|`
- [ ] Hashes tienen 40 caracteres hexadecimales

**Reportes (out/reports/):**
- [ ] `audit-summary.txt` contiene resumen ejecutivo
- [ ] `precommit-violations.txt` existe
- [ ] `prereceive-violations.txt` existe
- [ ] `commit-msg-violations.txt` existe (si se ejecutó hook)

**Distribución (dist/):**
- [ ] `repository-analyzer.tar.gz` generado con `make pack`
- [ ] Paquete pasa test de integridad con `gzip -t`

**Opcionales (pueden estar vacíos):**
- [ ] `tags.csv` (vacío si no hay tags)
- [ ] `tag-signatures.csv` (vacío si no hay tags)
- [ ] `remote-branches.txt` (vacío en repos sin remoto)