#!/bin/bash
# Starts the local server (MariaDB, realmd, mangosd) when it is not running,
# then the game client. The server keeps running after the client closes;
# tools/macos/stop-server.sh stops it.
#
#   tools/macos/play.sh                 server + client
#   tools/macos/play.sh --server-only   just the server
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$root/tools/macos/start-server.sh"
[ "${1:-}" = "--server-only" ] && exit 0

client="$root/release/build/macos/client-target/release/benilla"
[ -x "$client" ] || { echo "no client build: tools/macos/build-classic.sh client" >&2; exit 1; }
export BENILLA_HOME="$root/benilla-config"
export WOW_DATA="$root/Data"
export WGPU_BACKEND="${WGPU_BACKEND:-metal}"
cd "$root"
exec "$client" "$@"
