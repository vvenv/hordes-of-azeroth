#!/bin/bash
# Minimal local layout for a Darwin spike: binaries, extracted maps, SQL packages.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
ext="${HOA_EXTRACTED:-$root/../wow-data/vmangos-deploy/storage/mangosd/extracted-data}"
pkg="$root/release/cache/packages-v0.6.4"
mkdir -p "$pkg" "$root/server/run" "$root/server/logs" "$root/server/sql" "$root/server/downloads"

link_or_copy() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] || [ -L "$dest" ]; then return; fi
    ln -s "$src" "$dest"
    echo "link $dest"
}

# Server binaries from the local macOS build.
for name in mangosd realmd; do
    link_or_copy "$root/release/build/macos/server/bin/$name" "$root/server/run/$name"
done
link_or_copy "$root/release/build/macos/server/bin/libmariadb.dylib" "$root/server/run/libmariadb.dylib"
if [ ! -e "$root/server/run/Extractors" ]; then
    ln -s "$root/release/build/macos/server/bin/Extractors" "$root/server/run/Extractors"
fi
for conf in mangosd.conf.dist realmd.conf.dist; do
    link_or_copy "$root/release/build/macos/server/etc/$conf" "$root/server/run/$conf"
done

# Reuse already-extracted client data.
mkdir -p "$root/server/data"
for name in maps mmaps vmaps 5875; do
    link_or_copy "$ext/$name" "$root/server/data/$name"
done

# MariaDB tree: prefer packed release copy, else Homebrew prefix.
if [ ! -e "$root/server/mariadb/bin/mariadbd" ]; then
    if [ -d "$root/release/build/macos/mariadb/bin" ]; then
        rm -rf "$root/server/mariadb"
        ln -s "$root/release/build/macos/mariadb" "$root/server/mariadb"
    else
        rm -rf "$root/server/mariadb"
        ln -s "$(brew --prefix mariadb)" "$root/server/mariadb"
    fi
    echo "mariadb -> $root/server/mariadb"
fi

download() {
    local url="$1" out="$2"
    if [ -f "$out" ]; then return; fi
    echo "download $(basename "$out")"
    curl -fsSL -o "$out" "$url"
}

download "https://github.com/jonhaldors/hordes-of-azeroth/releases/download/packages-v0.6.4/world-db.zip" "$pkg/world-db.zip"
download "https://github.com/jonhaldors/hordes-of-azeroth/releases/download/packages-v0.6.4/migrations.zip" "$pkg/migrations.zip"
download "https://github.com/jonhaldors/hordes-of-azeroth/releases/download/packages-v0.6.4/config.zip" "$pkg/config.zip"
download "https://github.com/jonhaldors/hordes-of-azeroth/releases/download/v0.1.0/base-db.zip" "$pkg/base-db.zip"

unzip -qo "$pkg/world-db.zip" -d "$root/server/sql"
unzip -qo "$pkg/migrations.zip" -d "$root/server/sql"
unzip -qo "$pkg/base-db.zip" -d "$root/server/sql"
unzip -qo "$pkg/config.zip" -d "$root/tmp-config-pkg"
# overlay release configs without clobbering tracked config/ if already present
cp -f "$root/tmp-config-pkg"/config/*.conf "$root/config/" 2>/dev/null || true
cp -f "$root/tmp-config-pkg"/VERSION "$root/VERSION" 2>/dev/null || true
rm -rf "$root/tmp-config-pkg"

echo "smoke layout ready"
