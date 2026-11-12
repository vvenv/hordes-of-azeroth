#!/bin/bash
# Builds the classic databases (classic_realmd, classic_characters,
# classic_world, classic_logs) from stock vmangos: the core's sql/*.sql and
# migrations for realmd, characters and logs, and a vmangos world dump
# (db_latest release). tools/macos/setup-classic.sh downloads the dump and
# calls this; it can also run on its own.
#
#   tools/macos/init-classic-db.sh <world dump .sql> [--reset]
#   tools/macos/init-classic-db.sh --migrate-only
#
# --reset drops the four classic databases first. --migrate-only applies the
# core's migrations that the existing databases have not seen yet.
#
# When the old survivors databases are on this machine, the PLAYER and
# SQUADTEST accounts are copied from realmd, so their passwords stay.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
maria="$root/server/mariadb"
core="$root/server/core/sql"
port="${HOA_DB_PORT:-3306}"

db=("$maria/bin/mariadb" -h 127.0.0.1 -P "$port" -u root --skip-ssl)

# Applies the core's migrations of one kind that the database has not seen.
migrate() {
    local database="$1" kind="$2" f id
    for f in "$core/migrations"/*_"$kind".sql; do
        [ -f "$f" ] || continue
        id="$(basename "$f" .sql)"
        id="${id%_*}"   # the migrations table holds the timestamp alone
        if [ -z "$("${db[@]}" -N -B "$database" -e "SELECT 1 FROM migrations WHERE id='$id'" 2>/dev/null)" ]; then
            echo "migration $id"
            "${db[@]}" "$database" < "$f"
        fi
    done
}

if [ "${1:-}" = "--migrate-only" ]; then
    migrate classic_realmd logon
    migrate classic_characters characters
    migrate classic_logs logs
    migrate classic_world world
    exit 0
fi

world_dump="${1:?world dump .sql (vmangos db_latest), or --migrate-only}"
reset="${2:-}"

if [ "$reset" = "--reset" ]; then
    for d in classic_realmd classic_characters classic_world classic_logs; do
        "${db[@]}" -e "DROP DATABASE IF EXISTS $d"
    done
fi

for d in classic_realmd classic_characters classic_world classic_logs; do
    "${db[@]}" -e "CREATE DATABASE IF NOT EXISTS $d DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
        GRANT ALL PRIVILEGES ON $d.* TO 'mangos'@'localhost', 'mangos'@'127.0.0.1';"
done

echo "classic_realmd"
"${db[@]}" classic_realmd < "$core/logon.sql"
migrate classic_realmd logon
echo "classic_characters"
"${db[@]}" classic_characters < "$core/characters.sql"
migrate classic_characters characters
echo "classic_logs"
"${db[@]}" classic_logs < "$core/logs.sql"
migrate classic_logs logs
echo "classic_world <- $(basename "$world_dump") (a minute or two)"
"${db[@]}" classic_world < "$world_dump"
migrate classic_world world

"${db[@]}" classic_realmd -e "
    DELETE FROM realmlist;
    INSERT INTO realmlist (id, name, address, port) VALUES (1, 'Azeroth', '127.0.0.1', 8085);"

if [ "$("${db[@]}" -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='realmd' AND table_name='account'")" = "1" ]; then
    "${db[@]}" classic_realmd -e "
        INSERT IGNORE INTO account (id, username, gmlevel, v, s, expansion, locale)
            SELECT id, username, gmlevel, v, s, 0, locale FROM realmd.account WHERE username IN ('PLAYER', 'SQUADTEST');
        -- GM rights live in account_access (per realm); account.gmlevel is not read.
        REPLACE INTO account_access (id, gmlevel, RealmID)
            SELECT id, 6, 1 FROM account WHERE username IN ('PLAYER', 'SQUADTEST');"
    echo "copied the PLAYER and SQUADTEST accounts from realmd"
fi

echo "classic databases ready on 127.0.0.1:$port"
