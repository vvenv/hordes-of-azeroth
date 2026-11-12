#!/bin/bash
# Builds the classic databases (classic_realmd, classic_characters,
# classic_world, classic_logs) beside the old survivors ones, from stock
# vmangos: the core's sql/*.sql and migrations for realmd, characters and
# logs, and a vmangos world dump (db_latest release, matching the core commit).
#
#   tools/macos/init-classic-db.sh <world dump .sql> [--reset]
#
# --reset drops the four classic databases first. The PLAYER and SQUADTEST
# accounts are copied from the old realmd database, so their passwords stay.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
maria="$root/server/mariadb"
core="$root/server/core/sql"
port="${HOA_DB_PORT:-3306}"
world_dump="${1:?world dump .sql (vmangos db_latest)}"
reset="${2:-}"

db=("$maria/bin/mariadb" -h 127.0.0.1 -P "$port" -u root --skip-ssl)

if [ "$reset" = "--reset" ]; then
    for d in classic_realmd classic_characters classic_world classic_logs; do
        "${db[@]}" -e "DROP DATABASE IF EXISTS $d"
    done
fi

for d in classic_realmd classic_characters classic_world classic_logs; do
    "${db[@]}" -e "CREATE DATABASE IF NOT EXISTS $d DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
        GRANT ALL PRIVILEGES ON $d.* TO 'mangos'@'localhost', 'mangos'@'127.0.0.1';"
done

# Applies the core's migrations of one kind that the database has not seen.
migrate() {
    local database="$1" kind="$2" f id
    for f in "$core/migrations"/*_"$kind".sql; do
        [ -f "$f" ] || continue
        id="$(basename "$f" .sql)"
        if [ -z "$("${db[@]}" -N -B "$database" -e "SELECT 1 FROM migrations WHERE id='$id'" 2>/dev/null)" ]; then
            "${db[@]}" "$database" < "$f"
        fi
    done
}

echo "classic_realmd"
"${db[@]}" classic_realmd < "$core/logon.sql"
migrate classic_realmd logon
echo "classic_characters"
"${db[@]}" classic_characters < "$core/characters.sql"
migrate classic_characters characters
echo "classic_logs"
"${db[@]}" classic_logs < "$core/logs.sql"
migrate classic_logs logs
echo "classic_world <- $(basename "$world_dump")"
"${db[@]}" classic_world < "$world_dump"
migrate classic_world world

"${db[@]}" classic_realmd -e "
    DELETE FROM realmlist;
    INSERT INTO realmlist (id, name, address, port) VALUES (1, 'Azeroth', '127.0.0.1', 8085);
    INSERT IGNORE INTO account (id, username, gmlevel, v, s, expansion, locale)
        SELECT id, username, gmlevel, v, s, 0, locale FROM realmd.account WHERE username IN ('PLAYER', 'SQUADTEST');"

echo "classic databases ready on 127.0.0.1:$port"
