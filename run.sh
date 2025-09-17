#!/usr/bin/env bash
set -Eeuo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
ROOT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BACKEND_DIR="${BACKEND_DIR:-$ROOT_DIR/backend}"
FRONTEND_DIR="${FRONTEND_DIR:-$ROOT_DIR/frontend}"

BACKEND_PORT="${BACKEND_PORT:-8000}"
FRONTEND_PORT="${FRONTEND_PORT:-8080}"
EMULATOR_ID="${EMULATOR_ID:-Medium_Phone_API_36.0}"
ENV_FILE="${ENV_FILE:-$BACKEND_DIR/.env}"

# ── Helpers ──────────────────────────────────────────────────────────────────
ip() { hostname -I | awk '{print $1}'; }

ensure_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Comando mancante: $1" >&2; exit 1;
  }
}

help() {
  cat <<EOF
Usage: ./run.sh <command>

Commands:
  install                 - poetry install (backend) + flutter pub get (frontend)
  run-api                 - avvia FastAPI (uvicorn) su 0.0.0.0:${BACKEND_PORT}
  run-app-web             - avvia Flutter Web su 0.0.0.0:${FRONTEND_PORT}
  build-web               - flutter build web (frontend/build/web)
  serve-web               - serve statico build/ con python http.server su :${FRONTEND_PORT}
  run-app-android-emulator- avvia emulatore Android e lancia l'app
  qr                      - genera QR http://\$(ip):${FRONTEND_PORT} (richiede qrencode)
  kill-ports              - libera porte ${BACKEND_PORT} e ${FRONTEND_PORT}
  ip                      - stampa IP locale usato in LAN
  help                    - mostra questo aiuto
EOF
}

# ── Tasks ────────────────────────────────────────────────────────────────────
install() {
  ensure_cmd poetry
  ( cd "$BACKEND_DIR" && poetry install )
  ( cd "$FRONTEND_DIR" && flutter pub get )
}

run-api() {
  ensure_cmd poetry
  ( cd "$BACKEND_DIR" && \
    poetry run uvicorn app.main:app \
      --host 0.0.0.0 --port "${BACKEND_PORT}" \
      --env-file "${ENV_FILE}" --reload )
}

run-app-android-emulator() {
  ( cd "$FRONTEND_DIR" && \
    flutter emulators --launch "${EMULATOR_ID}" || true ; \
    flutter run )
}

run-app-web() {
  ( cd "$FRONTEND_DIR" && \
    flutter config --enable-web >/dev/null || true ; \
    flutter run -d web-server \
      --web-hostname=0.0.0.0 \
      --web-port="${FRONTEND_PORT}" )
}

build-web() {
  ( cd "$FRONTEND_DIR" && flutter build web )
}

serve-web() {
  # serve statico della build (comodo in LAN/iPhone)
  ( cd "$FRONTEND_DIR/build/web" && \
    python3 -m http.server "${FRONTEND_PORT}" --bind 0.0.0.0 )
}

qr() {
  ensure_cmd qrencode
  local host_ip; host_ip="$(ip)"
  qrencode -o "$ROOT_DIR/qrcode.png" "http://${host_ip}:${FRONTEND_PORT}"
  echo "✅ QR generato: $ROOT_DIR/qrcode.png  → http://${host_ip}:${FRONTEND_PORT}"
}

kill-ports() {
  for P in "${BACKEND_PORT}" "${FRONTEND_PORT}"; do
    pids="$(lsof -ti :"$P" || true)"
    [[ -n "${pids}" ]] && kill -9 ${pids} || true
  done
  echo "✅ Porte liberate."
}

# ── Dispatcher ────────────────────────────────────────────────────────────────
main() {
  local cmd="${1:-help}"; shift || true
  local TIMEFORMAT=$'⏱  Task completed in %3lR'
  case "$cmd" in
    install|run-api|run-app-web|build-web|serve-web|run-app-android-emulator|qr|kill-ports|ip|help)
      time "$cmd" "$@"
      ;;
    *)
      echo "Comando sconosciuto: $cmd"; echo; help; exit 1;;
  esac
}
main "$@"
