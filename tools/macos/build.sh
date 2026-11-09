#!/bin/bash
set -euo pipefail

part="${1:-all}"
client_source="${2:?client source}"
server_source="${3:?server source}"
out="${4:?out dir}"
work="${HOA_MAC_BUILD_WORK:-$HOME/.cache/hoa-build}"
jobs="$(sysctl -n hw.ncpu)"

mkdir -p "$work" "$out"

need() {
    command -v "$1" >/dev/null 2>&1 || { echo "missing $1" >&2; exit 1; }
}

need cmake
need cargo
need rustc
need pkg-config
need clang

openssl_prefix="$(brew --prefix openssl@3 2>/dev/null || brew --prefix openssl 2>/dev/null || true)"
mariadb_prefix="$(brew --prefix mariadb 2>/dev/null || brew --prefix mariadb-connector-c 2>/dev/null || true)"

sync_source() {
    mkdir -p "$2"
    rsync -a --delete --exclude=.git --exclude=/target "$1/" "$2/"
}

fix_rpath() {
    local binary="$1"
    install_name_tool -add_rpath "@loader_path" "$binary" 2>/dev/null || true
    if [ -n "${mariadb_prefix}" ] && [ -f "${mariadb_prefix}/lib/libmariadb.dylib" ]; then
        local lib
        lib="$(otool -L "$binary" | awk '/libmariadb/{print $1; exit}')"
        if [ -n "$lib" ]; then
            cp -f "${mariadb_prefix}/lib/libmariadb.dylib" "$(dirname "$binary")/libmariadb.dylib"
            install_name_tool -change "$lib" "@loader_path/libmariadb.dylib" "$binary" 2>/dev/null || true
            install_name_tool -id "@loader_path/libmariadb.dylib" "$(dirname "$binary")/libmariadb.dylib" 2>/dev/null || true
        fi
    fi
}

build_server() {
    sync_source "$server_source" "$work/src/server"
    local cmake_args=(
        -S "$work/src/server"
        -B "$work/cache/server"
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_EXTRACTORS=1
        -DBUILD_FOR_HOST_CPU=OFF
        -DCMAKE_INSTALL_PREFIX="$work/install/server"
    )
    if [ -n "$openssl_prefix" ]; then
        cmake_args+=("-DOPENSSL_ROOT_DIR=$openssl_prefix")
    fi
    if [ -n "$mariadb_prefix" ]; then
        cmake_args+=("-DMYSQL_INCLUDE_DIR=${mariadb_prefix}/include/mysql" "-DMYSQL_LIBRARIES=${mariadb_prefix}/lib/libmariadb.dylib")
    fi
    cmake "${cmake_args[@]}"
    cmake --build "$work/cache/server" -j"$jobs"
    rm -rf "$work/install/server"
    cmake --install "$work/cache/server"
    local bin="$work/install/server/bin"
    for binary in "$bin/mangosd" "$bin/realmd"; do
        fix_rpath "$binary"
        strip -x "$binary" || true
    done
    if [ -d "$bin/Extractors" ]; then
        find "$bin/Extractors" -type f -perm -111 -print0 | while IFS= read -r -d '' binary; do
            strip -x "$binary" || true
        done
    fi
    rm -rf "$out/server"
    mkdir -p "$out/server"
    cp -a "$work/install/server/." "$out/server/"
}

build_client() {
    sync_source "$client_source" "$work/src/client"
    cd "$work/src/client"
    rustup show active-toolchain >/dev/null 2>&1 || rustup toolchain install --profile minimal
    CARGO_TARGET_DIR="$work/cache/client" cargo build --profile ship --locked -p hoa --no-default-features
    mkdir -p "$out/client"
    cp "$work/cache/client/ship/HordesOfAzeroth" "$out/client/"
    strip -x "$out/client/HordesOfAzeroth" || true
}

case "$part" in
    server) build_server ;;
    client) build_client ;;
    all) build_server; build_client ;;
    *) echo "usage: $0 all|server|client <client> <server> <out>" >&2; exit 2 ;;
esac

find "$out" -type f \( -name HordesOfAzeroth -o -name mangosd -o -name realmd -o -name 'libmariadb*' \) -print
