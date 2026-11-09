#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
maria="$root/server/mariadb"
data="$root/server/mariadb-data"
cfg="$root/config/mariadb.ini"
sql="$root/server/sql"
port="${HOA_DB_PORT:-3307}"

mkdir -p "$root/server/logs" "$root/HordesOfAzeroth"
if [ ! -d "$data/mysql" ]; then
    echo "initializing datadir $data"
    rm -rf "$data"
    mkdir -p "$data"
    # Homebrew layout uses mariadb-install-db in scripts/ or bin/
    install_db="$maria/scripts/mariadb-install-db"
    [ -x "$install_db" ] || install_db="$maria/bin/mariadb-install-db"
    "$install_db" --defaults-file="$cfg" --basedir="$maria" --datadir="$data" \
        --auth-root-authentication-method=normal --skip-test-db
fi

if ! "$maria/bin/mariadb" -h 127.0.0.1 -P "$port" -u root --skip-ssl -e 'SELECT 1' >/dev/null 2>&1; then
    echo "starting mariadbd on $port"
    "$maria/bin/mariadbd" --defaults-file="$cfg" --basedir="$maria" --datadir="$data" --port="$port" \
        --pid-file="$root/server/logs/mariadb.pid" \
        --log-error="$root/server/logs/mariadb.err" &
    for i in $(seq 1 60); do
        if "$maria/bin/mariadb" -h 127.0.0.1 -P "$port" -u root --skip-ssl -e 'SELECT 1' >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
fi

db=("$maria/bin/mariadb" -h 127.0.0.1 -P "$port" -u root --skip-ssl)
"${db[@]}" < "$root/config/create-databases.sql"

# Prefer imported package dumps when present.
import_one() {
    local database="$1" file="$2"
    if [ ! -f "$file" ]; then
        echo "skip missing $file"
        return
    fi
    echo "import $database <- $(basename "$file")"
    "${db[@]}" "$database" < "$file"
}

import_one realmd "$sql/logon.sql"
import_one characters "$sql/characters.sql"
import_one logs "$sql/logs.sql"
import_one mangos "$sql/world.sql"

if [ -d "$sql/migrations" ]; then
    for f in "$sql/migrations"/*_logon.sql; do [ -f "$f" ] && "${db[@]}" realmd < "$f" || true; done
    for f in "$sql/migrations"/*_characters.sql; do [ -f "$f" ] && "${db[@]}" characters < "$f" || true; done
    for f in "$sql/migrations"/*_logs.sql; do [ -f "$f" ] && "${db[@]}" logs < "$f" || true; done
fi

"${db[@]}" -e "DELETE FROM realmd.realmlist; INSERT INTO realmd.realmlist (id, name, address, port) VALUES (1, 'Hordes of Azeroth', '127.0.0.1', 8085);"
# player / player GM 6 for spike
hash="$("$maria/bin/mariadb" -h 127.0.0.1 -P "$port" -u root --skip-ssl -N -B -e "SELECT UPPER(SHA1(CONCAT('player', SHA1('player'))));")"
"${db[@]}" -e "DELETE FROM realmd.account WHERE username='PLAYER'; INSERT INTO realmd.account (username, sha_pass_hash, gmlevel, expansion) VALUES ('PLAYER', '$hash', 6, 0);"

echo "database ready on 127.0.0.1:$port"
