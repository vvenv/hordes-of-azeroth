#!/bin/bash
# Pack a relocatable MariaDB tree from Homebrew into release/build/macos/mariadb.
set -euo pipefail

out="${1:-release/build/macos/mariadb}"
prefix="$(brew --prefix mariadb)"
version="$(brew list --versions mariadb | awk '{print $2}')"

rm -rf "$out"
mkdir -p "$out"/{bin,lib,share,scripts,include}

rsync -a "$prefix/bin/" "$out/bin/"
rsync -a "$prefix/lib/" "$out/lib/" --exclude='*.a' --exclude='pkgconfig' --exclude='plugin/auth_pam*' 
if [ -d "$prefix/share" ]; then
    rsync -a "$prefix/share/" "$out/share/"
fi
if [ -d "$prefix/scripts" ]; then
    rsync -a "$prefix/scripts/" "$out/scripts/"
elif [ -x "$prefix/bin/mariadb-install-db" ]; then
    mkdir -p "$out/scripts"
    ln -sf ../bin/mariadb-install-db "$out/scripts/mariadb-install-db"
fi

# Prefer @loader_path for shipped dylibs referenced by mariadbd.
if [ -f "$out/bin/mariadbd" ]; then
    install_name_tool -add_rpath "@loader_path/../lib" "$out/bin/mariadbd" 2>/dev/null || true
fi

cat > "$out/HOA-MARIADB.txt" <<EOF
Packaged from Homebrew mariadb $version on $(uname -m) $(sw_vers -productVersion)
Source prefix: $prefix
EOF

echo "packed MariaDB $version -> $out"
du -sh "$out"
