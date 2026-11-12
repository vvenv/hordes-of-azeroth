#!/bin/bash
# Creates a game account on the running local server (through the mangosd
# console). With "gm" it also gets GM rights (level 6), which the GMBox
# teleport, item and tool buttons need; bots and dungeons work without.
#
#   tools/macos/create-account.sh <name> <password> [gm]
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
name="${1:?account name}"
pass="${2:?password}"
fifo="$root/server/logs/mangosd.stdin"
[ -p "$fifo" ] && pgrep -x mangosd >/dev/null || { echo "the server is not running: tools/macos/play.sh --server-only" >&2; exit 1; }
out="$root/server/logs/mangosd.out"
before="$(wc -l < "$out")"
echo "account create $name $pass" > "$fifo"
if [ "${3:-}" = "gm" ]; then
    # The account row is written asynchronously; wait for it first.
    for _ in $(seq 1 20); do
        "$root/server/mariadb/bin/mariadb" -h 127.0.0.1 -u root --skip-ssl -N -B classic_realmd \
            -e "SELECT 1 FROM account WHERE username = UPPER('$name')" | grep -q 1 && break
        sleep 0.5
    done
    echo "account set gmlevel $name 6" > "$fifo"
fi
sleep 1
tail -n +"$((before + 1))" "$out" | sed 's/\x1b\[[0-9;]*m//g' | grep -iE "account|gm|exist|error" || true
