#!/bin/bash
# Pack a relocatable MariaDB tree from the Homebrew Cellar into release/build/macos/mariadb.
#
# The Cellar binaries link absolute Homebrew paths (openssl@4, pcre2, …). After
# install_name_tool rewrites those to @loader_path, Apple Silicon kills the
# unsigned Mach-O (SIGKILL) until we ad-hoc codesign again.
set -euo pipefail

out="${1:-release/build/macos/mariadb}"
prefix="$(brew --prefix mariadb)"
cellar="$(cd "$prefix" && pwd -P)"
version="$(brew list --versions mariadb | awk '{print $2}')"

rm -rf "$out"
mkdir -p "$(dirname "$out")"
ditto "$cellar" "$out"
mkdir -p "$out/lib"

bundle_dylib() {
    local src="$1"
    local name
    name="$(basename "$src")"
    if [ ! -f "$out/lib/$name" ]; then
        cp -f "$src" "$out/lib/$name"
        chmod u+w "$out/lib/$name"
    fi
}

# Runtime deps observed on mariadbd / mariadb / install helpers.
for dep in \
    "$(brew --prefix openssl@4)/lib/libssl.4.dylib" \
    "$(brew --prefix openssl@4)/lib/libcrypto.4.dylib" \
    "$(brew --prefix pcre2)/lib/libpcre2-8.0.dylib" \
    "$(brew --prefix pcre2)/lib/libpcre2-posix.3.dylib" \
    "$(brew --prefix lz4)/lib/liblz4.1.dylib" \
    "$(brew --prefix zstd)/lib/libzstd.1.dylib"
do
    [ -f "$dep" ] || continue
    bundle_dylib "$dep"
done

# Make bundled dylibs self-referential under @loader_path.
for dylib in "$out"/lib/*.dylib; do
    [ -f "$dylib" ] || continue
    base="$(basename "$dylib")"
    install_name_tool -id "@loader_path/$base" "$dylib" 2>/dev/null || true
done

# openssl libssl → libcrypto (Homebrew uses absolute Cellar path).
if [ -f "$out/lib/libssl.4.dylib" ] && [ -f "$out/lib/libcrypto.4.dylib" ]; then
    while IFS= read -r ref; do
        case "$ref" in
            *libcrypto.4.dylib)
                install_name_tool -change "$ref" "@loader_path/libcrypto.4.dylib" "$out/lib/libssl.4.dylib" 2>/dev/null || true
                ;;
        esac
    done < <(otool -L "$out/lib/libssl.4.dylib" | awk '/libcrypto\.4\.dylib/{print $1}')
fi

# pcre2-posix → pcre2-8
if [ -f "$out/lib/libpcre2-posix.3.dylib" ] && [ -f "$out/lib/libpcre2-8.0.dylib" ]; then
    while IFS= read -r ref; do
        case "$ref" in
            *libpcre2-8.0.dylib)
                install_name_tool -change "$ref" "@loader_path/libpcre2-8.0.dylib" "$out/lib/libpcre2-posix.3.dylib" 2>/dev/null || true
                ;;
        esac
    done < <(otool -L "$out/lib/libpcre2-posix.3.dylib" | awk '/libpcre2-8\.0\.dylib/{print $1}')
fi

rewrite_binary() {
    local bin="$1"
    local changed=0
    local ref name
    while IFS= read -r ref; do
        case "$ref" in
            /opt/homebrew/*|/usr/local/*)
                name="$(basename "$ref")"
                if [ -f "$out/lib/$name" ]; then
                    install_name_tool -change "$ref" "@loader_path/../lib/$name" "$bin"
                    changed=1
                fi
                ;;
        esac
    done < <(otool -L "$bin" 2>/dev/null | awk 'NR>1 {print $1}')
    if [ "$changed" -eq 1 ]; then
        install_name_tool -add_rpath "@loader_path/../lib" "$bin" 2>/dev/null || true
        codesign -s - --force --timestamp=none "$bin" >/dev/null
    fi
}

# Rewrite every Mach-O under bin/ (and plugin helpers that ship with the cellar).
while IFS= read -r -d '' bin; do
    rewrite_binary "$bin"
done < <(find "$out/bin" -type f -print0 2>/dev/null)

# Ad-hoc sign bundled dylibs after id/change rewrites.
for dylib in "$out"/lib/*.dylib; do
    [ -f "$dylib" ] || continue
    codesign -s - --force --timestamp=none "$dylib" >/dev/null 2>&1 || true
done

# Smoke: packed daemon must print a version without Homebrew on DYLD_LIBRARY_PATH.
if ! "$out/bin/mariadbd" --version >/dev/null; then
    echo "packed mariadbd --version failed" >&2
    exit 1
fi

cat > "$out/HOA-MARIADB.txt" <<EOF
Packaged from Homebrew mariadb $version cellar $cellar on $(uname -m) $(sw_vers -productVersion)
Relocatable: bundled openssl/pcre2/(lz4|zstd) under lib/ with @loader_path + ad-hoc codesign.
EOF

echo "packed MariaDB $version -> $out"
"$out/bin/mariadbd" --version
du -sh "$out"
otool -L "$out/bin/mariadbd" | grep -E 'pcre2|ssl|crypto|loader_path|homebrew' || true
