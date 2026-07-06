#!/usr/bin/env bash
set -euo pipefail

# Script para desplegar la API localmente usando Docker Compose
# Ubicación: backend/deploy_local.sh
# Uso:
#   ./deploy_local.sh up        # build + levantar en background
#   ./deploy_local.sh rebuild   # forzar rebuild y levantar
#   ./deploy_local.sh down      # bajar y limpiar contenedores
#   ./deploy_local.sh logs      # seguir logs del servicio

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

COMPOSE_FILE="docker-compose.yml"
PROJECT_NAME="credenciales_api_local"


# Detectar comando de compose disponible: preferir `docker compose`, caer a `docker-compose`
DOCKER_COMPOSE_CMD=""
if command -v docker >/dev/null 2>&1; then
  # `docker compose` está disponible en la mayoría de instalaciones modernas.
  if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
  fi
fi
if [ -z "$DOCKER_COMPOSE_CMD" ] && command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker-compose"
fi
if [ -z "$DOCKER_COMPOSE_CMD" ]; then
  echo "ERROR: ni 'docker compose' ni 'docker-compose' están disponibles en PATH. Instala Docker Engine o docker-compose."
  exit 1
fi

cmd="${1:-up}"

case "$cmd" in
  up)
    echo "Construyendo y levantando servicios (detached)..."
    docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" up --build -d
    echo "Servicios levantados. API disponible en http://localhost:8081 (si está mapeado)."
    ;;
  rebuild)
    echo "Reconstruyendo imágenes y levantando servicios (detached)..."
    docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" build --no-cache
    docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" up -d
    echo "Reconstrucción completada."
    ;;
  down)
    echo "Bajando servicios y eliminando contenedores..."
    docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" down --remove-orphans
    echo "Contenedores detenidos y eliminados."
    ;;
  logs)
    echo "Mostrando logs (Ctrl+C para salir)..."
    docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" logs -f --tail=200
    ;;
  *)
    echo "Uso: $0 {up|rebuild|down|logs}"
    exit 2
    ;;
esac

exit 0
