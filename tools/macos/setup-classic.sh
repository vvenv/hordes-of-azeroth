#!/bin/bash
# Sets up the classic game on this Mac after tools/macos/build-classic.sh:
# server links, MariaDB, the classic databases, config, client data, addons.
# Safe to run again: it keeps what is already there.
#
#   tools/macos/setup-classic.sh [--reset-db]
#
# --reset-db drops and rebuilds the classic databases (characters too).
#
# Where it looks for game data (override with these variables):
#   WOW_DATA_ROOT  folder holding the clients and extracted server data
#                  (default: ../wow-data next to this repository)
#   CLIENT_LOCALE  zhCN (default) or enUS: which client's MPQs Data/ links to
#                  ($WOW_DATA_ROOT/client-zhCN/Data or $WOW_DATA_ROOT/client/Data)
#   HOA_EXTRACTED  maps, vmaps, mmaps and dbc extracted by the vmangos
#                  extractors (default: $WOW_DATA_ROOT/vmangos-deploy/
#                  storage/mangosd/extracted-data)
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
wow_data="${WOW_DATA_ROOT:-$root/../wow-data}"
locale="${CLIENT_LOCALE:-zhCN}"
extracted="${HOA_EXTRACTED:-$wow_data/vmangos-deploy/storage/mangosd/extracted-data}"
server="$root/release/build/macos/server-classic"
reset=""
[ "${1:-}" = "--reset-db" ] && reset="--reset"

step() { echo; echo "== $*"; }
die() { echo "error: $*" >&2; exit 1; }

# ---------------------------------------------------------------- server ---
step "server binaries and data"
[ -x "$server/bin/mangosd" ] || die "no server build; run tools/macos/build-classic.sh server first"
mkdir -p "$root/server/run" "$root/server/logs" "$root/server/data"
for f in mangosd realmd; do ln -sfn "$server/bin/$f" "$root/server/run/$f"; done
for f in mangosd.conf.dist realmd.conf.dist; do ln -sfn "$server/etc/$f" "$root/server/run/$f"; done
for d in maps vmaps mmaps 5875; do
    if [ ! -e "$root/server/data/$d" ]; then
        [ -d "$extracted/$d" ] || die "missing $extracted/$d (set HOA_EXTRACTED)"
        ln -s "$extracted/$d" "$root/server/data/$d"
        echo "link server/data/$d"
    fi
done

# --------------------------------------------------------------- MariaDB ---
step "MariaDB"
if [ ! -e "$root/server/mariadb/bin/mariadbd" ]; then
    prefix="$(brew --prefix mariadb 2>/dev/null)" || die "brew install mariadb"
    ln -sfn "$prefix" "$root/server/mariadb"
    echo "link server/mariadb -> $prefix"
fi
maria="$root/server/mariadb"
data="$root/server/mariadb-data"
cfg="$root/config/mariadb.ini"
if [ ! -d "$data/mysql" ]; then
    echo "initialising server/mariadb-data"
    install_db="$maria/scripts/mariadb-install-db"
    [ -x "$install_db" ] || install_db="$maria/bin/mariadb-install-db"
    "$install_db" --defaults-file="$cfg" --basedir="$maria" --datadir="$data" \
        --socket="$root/server/logs/mysql.sock" --innodb-buffer-pool-size=128M \
        --auth-root-authentication-method=normal --skip-test-db > "$root/server/logs/mariadb-install.log" 2>&1
fi
db=("$maria/bin/mariadb" -h 127.0.0.1 -P 3306 -u root --skip-ssl)
if ! "${db[@]}" -e 'SELECT 1' >/dev/null 2>&1; then
    echo "starting mariadbd"
    nohup "$maria/bin/mariadbd" --defaults-file="$cfg" --basedir="$maria" --datadir="$data" --port=3306 \
        --socket="$root/server/logs/mysql.sock" --pid-file="$root/server/logs/mariadb.pid" \
        --log-error="$root/server/logs/mariadb.err" >/dev/null 2>&1 &
    for _ in $(seq 1 60); do "${db[@]}" -e 'SELECT 1' >/dev/null 2>&1 && break; sleep 1; done
fi
"${db[@]}" -e 'SELECT 1' >/dev/null 2>&1 || die "MariaDB did not start (server/logs/mariadb.err)"
"${db[@]}" -e "CREATE USER IF NOT EXISTS 'mangos'@'localhost' IDENTIFIED BY 'mangos';
               CREATE USER IF NOT EXISTS 'mangos'@'127.0.0.1' IDENTIFIED BY 'mangos';"

# ------------------------------------------------------------- databases ---
step "classic databases"
have_world="$("${db[@]}" -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='classic_world' AND table_name='creature'")"
if [ "$have_world" = "0" ] || [ -n "$reset" ]; then
    # The vmangos development snapshot (db_latest) holds the world database
    # of the newest upstream commit; the core's own migrations go on top.
    cache="$root/release/cache/vmangos-db"
    mkdir -p "$cache"
    asset="$(curl -fsSL https://api.github.com/repos/vmangos/core/releases/tags/db_latest |
        python3 -c 'import json,sys; print(next(a["name"] for a in json.load(sys.stdin)["assets"] if a["name"].startswith("db-") and "sqlite" not in a["name"]))')"
    if [ ! -f "$cache/$asset" ]; then
        echo "downloading vmangos $asset (about 30 MB)"
        curl -fL --progress-bar -o "$cache/$asset.part" \
            "https://github.com/vmangos/core/releases/download/db_latest/$asset"
        mv "$cache/$asset.part" "$cache/$asset"
    fi
    rm -rf "$cache/mysql-dump"
    unzip -q -o "$cache/$asset" -d "$cache"
    bash "$root/tools/macos/init-classic-db.sh" "$cache/mysql-dump/mangos.sql" ${reset:+--reset}
else
    echo "classic_world is there (--reset-db rebuilds it)"
    # New migrations from server/core still go in.
    bash "$root/tools/macos/init-classic-db.sh" --migrate-only
fi

# ---------------------------------------------------------------- config ---
step "server config"
bash "$root/tools/macos/apply-config.sh"

# ----------------------------------------------------------- client data ---
step "client data ($locale)"
case "$locale" in
    zhCN) client_data="$wow_data/client-zhCN/Data" ;;
    enUS) client_data="$wow_data/client/Data" ;;
    *) die "CLIENT_LOCALE is zhCN or enUS" ;;
esac
if [ ! -e "$root/Data" ]; then
    [ -d "$client_data" ] || die "missing $client_data (set WOW_DATA_ROOT)"
    mkdir "$root/Data"
    for f in "$client_data"/*.MPQ; do ln -s "$f" "$root/Data/"; done
    echo "Data/ links the MPQs of $client_data"
else
    echo "keep Data/ (move it away to relink)"
fi

# The client's own settings: the classic realm, and no script memory cap
# (pfQuest and AtlasLoot need more than 1.12's 48 MB; 0 = no limit).
home="$root/benilla-config"
mkdir -p "$home"
toml="$home/config.toml"
[ -f "$toml" ] || printf '[cvars]\n' > "$toml"
python3 - "$toml" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
want = {"realmList": "127.0.0.1", "realmName": "Azeroth", "scriptMemory": "0"}
for key, value in want.items():
    line = '%s = "%s"' % (key, value)
    if re.search(r'^%s\s*=' % key, s, re.M):
        s = re.sub(r'^%s\s*=.*$' % key, line, s, flags=re.M)
    else:
        s = s.replace("[cvars]\n", "[cvars]\n" + line + "\n", 1)
open(p, "w", encoding="utf-8").write(s)
PY
echo "benilla-config/config.toml: realm Azeroth, scriptMemory 0"

# ---------------------------------------------------------------- addons ---
step "addons"
bash "$root/tools/macos/install-addons.sh" | grep -v '^addon ' || true

echo
echo "Done. Create an account once with"
echo "  tools/macos/create-account.sh <name> <password> [gm]"
echo "then start the game with tools/macos/play.sh"
