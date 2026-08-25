#!/usr/bin/env bash
# start-obsidian-debug.sh
# Lanza instancia AISLADA de Obsidian con debug port 9222.
#   - Abre ventana tmux "obs-debug" con los logs en vivo
#   - Obsidian abre su propia ventana GNOME vía Wayland
#   - Idempotente: no relanza si ya está corriendo
#
# Uso:
#   ./start-obsidian-debug.sh          # levantar
#   ./start-obsidian-debug.sh --kill   # cerrar

set -euo pipefail

# ── config ───────────────────────────────────────────────────────────────────
OBSIDIAN_BIN="${OBSIDIAN_BIN:-/home/manu/.nix-profile/bin/obsidian}"
DEBUG_PORT="${DEBUG_PORT:-9222}"
USER_DATA_DIR="${USER_DATA_DIR:-/tmp/obs-debug-vault}"
LOCK_FILE="/tmp/obs-debug.pid"
TMUX_WINDOW="obs-debug"
WAIT_TIMEOUT=25  # segundos máximos esperando el puerto

# Wayland: leer de entorno actual o descubrir el socket activo
if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  WAYLAND_DISPLAY=$(ls /run/user/$(id -u)/wayland-* 2>/dev/null | head -1 | xargs -I{} basename {} || echo "wayland-0")
fi
XDG_RT="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# ── helpers ───────────────────────────────────────────────────────────────────

is_running() {
  [[ -f "$LOCK_FILE" ]] && kill -0 "$(cat "$LOCK_FILE")" 2>/dev/null
}

tmux_window_exists() {
  tmux list-windows 2>/dev/null | grep -q "^[0-9]*: ${TMUX_WINDOW}"
}

kill_instance() {
  local killed=0
  if is_running; then
    echo "→ Matando proceso Obsidian debug (PID $(cat "$LOCK_FILE"))..."
    kill "$(cat "$LOCK_FILE")" 2>/dev/null && killed=1
    rm -f "$LOCK_FILE"
  fi
  if tmux_window_exists; then
    echo "→ Cerrando ventana tmux '${TMUX_WINDOW}'..."
    tmux kill-window -t "${TMUX_WINDOW}" 2>/dev/null && killed=1
  fi
  [[ $killed -eq 1 ]] && echo "✓ Instancia debug cerrada." || echo "No había instancia activa."
  exit 0
}

wait_for_port() {
  local i=0
  echo -n "→ Esperando puerto ${DEBUG_PORT}"
  while ! curl -sf "http://127.0.0.1:${DEBUG_PORT}/json/version" > /dev/null 2>&1; do
    sleep 1
    echo -n "."
    (( i++ ))
    if (( i >= WAIT_TIMEOUT )); then
      echo -e "\n✗ Timeout: puerto ${DEBUG_PORT} no respondió en ${WAIT_TIMEOUT}s."
      exit 1
    fi
  done
  echo ""
}

# ── main ──────────────────────────────────────────────────────────────────────

[[ "${1:-}" == "--kill" ]] && kill_instance

if is_running && tmux_window_exists; then
  echo "✓ Instancia debug ya activa (PID $(cat "$LOCK_FILE"))."
  echo "  Tmux:  ventana '${TMUX_WINDOW}'"
  echo "  Port:  ${DEBUG_PORT}"
  exit 0
fi

# Limpiar estado inconsistente
rm -f "$LOCK_FILE"
tmux kill-window -t "${TMUX_WINDOW}" 2>/dev/null || true

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Obsidian Debug Instance"
echo "  Port:     ${DEBUG_PORT}"
echo "  Vault:    ${USER_DATA_DIR}"
echo "  Wayland:  ${WAYLAND_DISPLAY}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Lanzar Obsidian dentro de una nueva ventana tmux
# La ventana queda abierta mostrando stdout/stderr en vivo
tmux new-window -n "${TMUX_WINDOW}" \
  "WAYLAND_DISPLAY=${WAYLAND_DISPLAY} XDG_RUNTIME_DIR=${XDG_RT} \
  ${OBSIDIAN_BIN} \
  --remote-debugging-port=${DEBUG_PORT} \
  --remote-debugging-address=127.0.0.1 \
  --user-data-dir=${USER_DATA_DIR} \
  --ozone-platform=wayland; \
  echo ''; echo '[ Obsidian cerrado — presiona cualquier tecla para salir ]'; read -n1"

# Obtener PID del proceso electron recién lanzado
sleep 2
OBS_PID=$(pgrep -f "user-data-dir=${USER_DATA_DIR}" | head -1 || true)
if [[ -n "$OBS_PID" ]]; then
  echo "$OBS_PID" > "$LOCK_FILE"
  echo "→ PID: ${OBS_PID} guardado en ${LOCK_FILE}"
else
  echo "⚠ No se encontró PID (el proceso puede tardar un poco más)"
fi

wait_for_port

# Info final
PAGE_TITLE=$(curl -s "http://127.0.0.1:${DEBUG_PORT}/json" \
  | python3 -c "
import sys, json
try:
  pages = [p for p in json.load(sys.stdin) if p['type'] == 'page']
  print(pages[0]['title'][:60] if pages else 'sin páginas')
except: print('error leyendo páginas')
" 2>/dev/null || echo "n/a")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Obsidian debug listo."
echo "  Tmux:   ventana '${TMUX_WINDOW}' (logs en vivo)"
echo "  Puerto: ws://127.0.0.1:${DEBUG_PORT}"
echo "  Página: ${PAGE_TITLE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
