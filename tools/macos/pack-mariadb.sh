#!/bin/bash
# Pack a relocatable MariaDB tree from the Homebrew Cellar into release/build/macos/mariadb.
# Copy the real Cellar directory (not the opt symlink tree): rsync of keg-only linked
# layouts left mariadbd unusable (SIGKILL on bootstrap) in the first spike.
set -euo pipefail

out="${1:-release/build/macos/mariadb}"
prefix="$(brew --prefix mariadb)"
cellar="$(cd "$prefix" && pwd -P)"
version="$(brew list --versions mariadb | awk '{print $2}')"

rm -rf "$out"
mkdir -p "$(dirname "$out")"
# Full cellar copy keeps relative script paths and dylib ids consistent enough for local smoke.
# Player releases should still prefer a purpose-built relocatable tarball once signed.
ditto "$cellar" "$out"

if [ -f "$out/bin/mariadbd" ]; then
    install_name_tool -add_rpath "@loader_path/../lib" "$out/bin/mariadbd" 2>/dev/null || true
fi

cat > "$out/HOA-MARIADB.txt" <<EOF
Packaged from Homebrew mariadb $version cellar $cellar on $(uname -m) $(sw_vers -productVersion)
EOF

echo "packed MariaDB $version -> $out"
du -sh "$out"
