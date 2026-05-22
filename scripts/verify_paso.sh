#!/usr/bin/env bash
# verify_paso.sh — corre los checks de la sección "Verificación automatizada"
# de un PASO_*.md y devuelve exit 0 si todos pasan, exit 1 si alguno falla.
#
# Uso:
#   ./verify_paso.sh PASO_S01_01
#   ./verify_paso.sh PASO_S01_01 --dry-run    (solo lista los comandos, no ejecuta)
#
# Convención del PASO_*.md:
#   La sección debe tener este formato exacto:
#
#   ## Verificación automatizada
#
#   ```bash
#   <comando 1>
#   <comando 2>
#   ...
#   ```
#
# Cada línea de comando debe ser ejecutable y devolver exit code interpretable
# (0 = PASS, ≠0 = FAIL). Se ignoran líneas en blanco y comentarios (#).

set -eu

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
PASOS_DIR="$ROOT_DIR/docs/08-desarrollo-con-ia/pasos"

if [ $# -lt 1 ]; then
  echo "Uso: $0 PASO_X_Y [--dry-run]" >&2
  echo "     $0 --list                 (lista todos los pasos disponibles)" >&2
  exit 2
fi

if [ "$1" = "--list" ]; then
  ls "$PASOS_DIR"/PASO_*.md | xargs -n1 basename | sed 's/\.md$//'
  exit 0
fi

PASO_ID="$1"
DRY_RUN="${2:-}"

# Buscar el archivo (puede tener sufijo descriptivo: PASO_S01_02.md)
PASO_FILE=$(find "$PASOS_DIR" -maxdepth 1 -type f -name "${PASO_ID}*.md" | head -1)

if [ -z "$PASO_FILE" ] || [ ! -f "$PASO_FILE" ]; then
  echo "ERROR: no se encontró archivo para $PASO_ID en $PASOS_DIR" >&2
  exit 2
fi

echo "→ Verificando: $PASO_ID  ($PASO_FILE)"
echo "  cwd: $(pwd)"
echo

# Extraer el bloque de "Verificación automatizada" (o "Verificación")
# Busca el primer bloque ```bash...``` después de un encabezado de Verificación.
COMMANDS=$(awk '
  /^## Verificación( automatizada)?[[:space:]]*$/ { in_section = 1; next }
  in_section && /^```bash[[:space:]]*$/ { in_block = 1; next }
  in_section && in_block && /^```[[:space:]]*$/ { in_block = 0; in_section = 0; next }
  in_section && in_block { print }
' "$PASO_FILE")

if [ -z "$COMMANDS" ]; then
  echo "ERROR: no se encontró bloque \`\`\`bash en sección 'Verificación automatizada' de $PASO_ID" >&2
  echo "       Agregar la sección al PASO siguiendo PASO_TEMPLATE.md" >&2
  exit 2
fi

PASS=0
FAIL=0
FAIL_CMDS=()

while IFS= read -r CMD; do
  # Saltar líneas en blanco y comentarios puros
  [ -z "$(echo "$CMD" | tr -d '[:space:]')" ] && continue
  echo "$CMD" | grep -qE '^[[:space:]]*#' && continue

  # Quitar el comentario inline (todo lo que sigue a "  # ")
  CLEAN_CMD=$(echo "$CMD" | sed -E 's/[[:space:]]+#[[:space:]].*$//')

  echo "  ▶ $CLEAN_CMD"

  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "    (dry-run)"
    continue
  fi

  if bash -c "$CLEAN_CMD" >/dev/null 2>&1; then
    echo "    ✓ PASS"
    PASS=$((PASS + 1))
  else
    echo "    ✗ FAIL (exit $?)"
    FAIL=$((FAIL + 1))
    FAIL_CMDS+=("$CLEAN_CMD")
  fi
done <<< "$COMMANDS"

echo
echo "─── Resultado: $PASS PASS, $FAIL FAIL ───"

if [ "$FAIL" -gt 0 ]; then
  echo
  echo "Comandos que fallaron:"
  for c in "${FAIL_CMDS[@]}"; do
    echo "  - $c"
  done
  exit 1
fi

exit 0
