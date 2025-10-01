# Sprint 1 – Auditoría de Políticas de Repositorios Git

## Descripción general

Este proyecto implementa un **sistema de auditoría automatizada** para validar políticas de seguridad y buenas prácticas en repositorios Git. El enfoque es modular y extensible, permitiendo:

- Validación automática del entorno de ejecución.
- Extracción exhaustiva de información del repositorio (ramas, commits, tags, firmas).
- Consulta de políticas de protección en plataformas remotas (GitHub).
- Generación de reportes detallados de auditoría.
- Detección de violaciones de políticas (preparado para expansión futura).

El sistema sigue principios de **scripting robusto** con manejo de errores, logging estructurado y limpieza automática de recursos.

### Tecnologías y herramientas

- **Bash scripting avanzado** (trap handlers, funciones modulares).
- **Git** (análisis de historial, ramas, tags y firmas).
- **GitHub API** (consulta de políticas de protección).
- **Herramientas Unix**: `jq`, `curl`, `grep`, `awk`, `sed`, `cut`, `sort`, `uniq`.
- **Automatización**: `Makefile`.

---

## Estructura del proyecto

```text
proyecto-auditoria-git/
├── Makefile                          # Reglas de construcción y comandos
├── README.md                         # Documentación del proyecto
├── policy-auditor.sh                 # Script principal de orquestación
├── src/
│   ├── utils.sh                     # Funciones de apoyo y logging
│   ├── validate_environment.sh      # Validación de dependencias
│   ├── prepare_workspace.sh         # Preparación de directorios
│   ├── setup_repository.sh          # Configuración de acceso al repo
│   ├── git-info-extractor.sh        # Extracción de información Git
│   └── query-remote-policies.sh     # Consulta de políticas remotas
└── out/
    ├── raw/                         # Datos extraídos en CSV/texto
    │   ├── branches.txt
    │   ├── commits.csv
    │   ├── commit-graph.txt
    │   ├── signed-tags.txt
    │   ├── reflog.txt
    │   └── remote-branch-policies.csv
    └── audit-config.env             # Configuración de la auditoría
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
   ./policy-auditor.sh
   ```

4. **Revisar resultados**

   ```bash
   cat out/audit-report.txt
   ls -la out/raw/
   ```

---

## Funcionalidades implementadas

### policy-auditor.sh

- Orquestación del flujo completo de auditoría.
- Carga de módulos con manejo de errores.
- Generación de reporte consolidado con metadatos.
- Códigos de salida estandarizados (0: éxito, 1: error crítico, 2: advertencias).

### validate_environment.sh

- Validación de comandos críticos del sistema.
- Verificación de variables de entorno obligatorias.
- Validación de formato de parámetros numéricos.

### prepare_workspace.sh

- Creación automática de estructura de directorios.
- Generación de archivo de configuración de auditoría.
- Limpieza de ejecuciones previas (opcional).

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