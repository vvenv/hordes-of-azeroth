#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
run="$root/server/run"
logs="$root/server/logs"
maria="$(cd "$root/server/mariadb" && pwd -P)"
data="$root/server/mariadb-data"
cfg="$root/config/mariadb.ini"
mkdir -p "$logs"

if ! "$maria/bin/mariadb" -h127.0.0.1 -P3306 -uroot --skip-ssl -e 'SELECT 1' >/dev/null 2>&1; then
    echo "starting mariadbd"
    nohup "$maria/bin/mariadbd" --defaults-file="$cfg" --basedir="$maria" --datadir="$data" --port=3306 \
        --socket="$logs/mysql.sock" \
        --pid-file="$logs/mariadb.pid" --log-error="$logs/mariadb.err" >/dev/null 2>&1 &
    for i in $(seq 1 60); do
        "$maria/bin/mariadb" -h127.0.0.1 -P3306 -uroot --skip-ssl -e 'SELECT 1' >/dev/null 2>&1 && break
        sleep 1
    done
fi

# The daemons exit when stdin hits EOF. Opening a FIFO read-write as stdin
# gives the daemon its own writer, so stdin never ends (works in bash 3.2).
new_fifo() {
    rm -f "$1"
    mkfifo "$1"
}

if ! lsof -nP -iTCP:3724 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "starting realmd"
    new_fifo "$logs/realmd.stdin"
    ( cd "$run" || exit 1; nohup ./realmd -c realmd.conf <>"$logs/realmd.stdin" >"$logs/realmd.out" 2>&1 & echo $! >"$logs/realmd.pid" )
fi

if ! lsof -nP -iTCP:8085 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "starting mangosd"
    new_fifo "$logs/mangosd.stdin"
    ( cd "$run" || exit 1; nohup ./mangosd -c mangosd.conf <>"$logs/mangosd.stdin" >"$logs/mangosd.out" 2>&1 & echo $! >"$logs/mangosd.pid" )
fi

for i in $(seq 1 120); do
    r=0; w=0
    lsof -nP -iTCP:3724 -sTCP:LISTEN >/dev/null 2>&1 && r=1
    lsof -nP -iTCP:8085 -sTCP:LISTEN >/dev/null 2>&1 && w=1
    if [ "$r$w" = 11 ]; then
        echo "server ready on 127.0.0.1 (auth 3724, world 8085)"
        exit 0
    fi
    sleep 1
done
echo "server failed to become ready" >&2
tail -50 "$logs/mangosd.out" >&2 || true
exit 1
