#!/bin/bash
# Stage a macOS Install→Play layout into a WoW 1.12.1 folder for local smoke.
# Default target: a sibling work folder under release/build/macos/dev-install that
# reuses ../wow-data/client Data + WoW.exe via symlinks (does not mutate wow-data).
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
build="$root/release/build/macos"
wow_client="${HOA_WOW_CLIENT:-$root/../wow-data/client}"
dest="${1:-$build/dev-install}"

need() { [ -e "$1" ] || { echo "missing $1" >&2; exit 1; }; }

need "$build/launcher/HoALauncher"
need "$build/client/HordesOfAzeroth"
need "$build/server/bin/mangosd"
need "$build/server/bin/realmd"
need "$build/mariadb.tar.gz"
need "$wow_client/Data"
need "$wow_client/WoW.exe"

mkdir -p "$dest" "$dest/server/run" "$dest/server/logs" "$dest/config" \
  "$dest/Interface/GlueXML" "$dest/Interface/AddOns" "$dest/benilla-config/AddOns" "$dest/Logs"

# Game data: link, do not copy.
ln -sfn "$wow_client/Data" "$dest/Data"
ln -sfn "$wow_client/WoW.exe" "$dest/WoW.exe"

# Player client + launcher (binary uses .arm64 so it does not collide with HordesOfAzeroth/ data dir)
cp -f "$build/client/HordesOfAzeroth" "$dest/HordesOfAzeroth.arm64"
chmod +x "$dest/HordesOfAzeroth.arm64"
cp -f "$build/launcher/HoALauncher" "$dest/HoALauncher"
chmod +x "$dest/HoALauncher"

# Server binaries
cp -f "$build/server/bin/mangosd" "$build/server/bin/realmd" "$dest/server/run/"
chmod +x "$dest/server/run/mangosd" "$dest/server/run/realmd"
if [ -f "$build/server/bin/libmariadb.dylib" ]; then
  cp -f "$build/server/bin/libmariadb.dylib" "$dest/server/run/"
fi
if [ -d "$build/server/etc" ]; then
  cp -f "$build/server/etc/"*.dist "$dest/server/run/" 2>/dev/null || true
fi
if [ -d "$build/server/bin/Extractors" ]; then
  rsync -a --delete "$build/server/bin/Extractors/" "$dest/server/run/Extractors/"
fi

# MariaDB portable tree
rm -rf "$dest/server/mariadb"
tar -xzf "$build/mariadb.tar.gz" -C "$dest/server"
# tarball root is mariadb/
[ -d "$dest/server/mariadb" ] || { echo "mariadb.tar.gz layout unexpected" >&2; exit 1; }

# Glue + addon (BonkGlue hero UI)
rsync -a --delete "$root/Interface/GlueXML/" "$dest/Interface/GlueXML/"
if [ -d "$root/Interface/AddOns/HordesOfAzeroth" ]; then
  rsync -a --delete "$root/Interface/AddOns/HordesOfAzeroth/" "$dest/Interface/AddOns/HordesOfAzeroth/"
  rsync -a --delete "$root/Interface/AddOns/HordesOfAzeroth/" "$dest/benilla-config/AddOns/HordesOfAzeroth/"
fi

# Launcher config seeds
if [ -d "$root/config" ]; then
  rsync -a "$root/config/" "$dest/config/" --exclude '*.overrides.conf'
fi
# Prefer clean dist overrides if present
for f in mangosd realmd; do
  if [ -f "$root/config/${f}.conf.dist" ]; then
    cp -f "$root/config/${f}.conf.dist" "$dest/config/" 2>/dev/null || true
  fi
done

# VERSION marker so the folder looks installed
printf '%s\n' 'mac-dev-stage' > "$dest/VERSION"

echo "staged: $dest"
echo "  launcher: $dest/HoALauncher"
echo "  client:   $dest/HordesOfAzeroth.arm64"
echo "  data:     $dest/Data -> $wow_client/Data"
ls -la "$dest/HoALauncher" "$dest/HordesOfAzeroth.arm64" "$dest/server/run/mangosd" "$dest/server/mariadb/bin/mariadbd" | awk '{print $1, $5, $9}'
