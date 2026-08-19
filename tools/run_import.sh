#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
PY_SCRIPT="$SCRIPT_DIR/importar_credenciales.py"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "No se encontró $ENV_FILE. Crea tools/.env con la configuración necesaria."
  exit 1
fi

if [[ ! -f "$PY_SCRIPT" ]]; then
  echo "No se encontró $PY_SCRIPT. Asegúrate de que tools/importar_credenciales.py exista."
  exit 1
fi

# Exportar variables del .env
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

echo "Ejecutando importación de credenciales..."
python3 "$PY_SCRIPT"
EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "El script de importación falló con código $EXIT_CODE"
  exit $EXIT_CODE
fi

echo "Importación finalizada correctamente."
