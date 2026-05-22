---
id: PASO_S00_02
equipo: C
bloque: 0
dep: [PASO_S00_01]
siguiente: PASO_S00_03
context_files: []
outputs: []
---

# PASO 0.1 — Instalar herramientas
**Grupo legacy:** 0 — Infraestructura | **Equipo:** C | **Dificultad:** 🟢 | **Tiempo:** 30 min

## Navegación
← **Anterior:** [PASO_S00_01](PASO_S00_01.md) — Contratos de API y protocolo WebSocket definidos
→ **Siguiente:** [PASO_S00_03](PASO_S00_03.md) — Levantar servicios Docker

## Archivos a cargar junto a este
Ninguno. Este paso solo requiere comandos de instalación.

## Qué construye este paso
Instala las herramientas necesarias para desarrollar el proyecto: Java 21, Maven, Node 20, Angular CLI y Docker Desktop.

## Comandos de instalación

```bash
# Java 21
sudo apt install -y openjdk-21-jdk

# Maven
sudo apt install -y maven

# Node 20 (via nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# Angular CLI
npm install -g @angular/cli@latest

# Docker Desktop
# → https://www.docker.com/products/docker-desktop
```

## Errores comunes

- `nvm: command not found` después de instalar → ejecutar `source ~/.bashrc` y reiniciar la terminal
- `ng: command not found` → verificar que npm install -g terminó sin errores, reiniciar terminal
- En macOS: usar Homebrew en lugar de apt: `brew install openjdk@21 maven node`

## Verificación

```bash
java -version
# PASS: output contiene "openjdk version "21"
# FAIL: otra versión o "java: command not found"

mvn -version
# PASS: output contiene "Apache Maven 3"
# FAIL: "mvn: command not found"

node -v
# PASS: output contiene "v20"
# FAIL: otra versión o error

docker --version
# PASS: output contiene "Docker version"
# FAIL: "Cannot connect to the Docker daemon"

ng version --skip-confirmation 2>/dev/null | grep "Angular CLI"
# PASS: output contiene "Angular CLI: 21"
# FAIL: "ng: command not found" o versión diferente
```

## Dependencias
Ninguna. Es el primer paso.
