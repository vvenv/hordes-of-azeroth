#!/bin/bash
# Builds the classic game on an Apple Silicon Mac.
#
#   tools/macos/build-classic.sh [server|client|all]     (default: all)
#
# server: CMake configure + build + install of server/core (mangosd, realmd)
#         into release/build/macos/server-classic. The configure step runs
#         every time, because mangosd embeds the list of sql/migrations and a
#         new migration file needs a fresh configure.
# client: cargo build of the client (benilla) into
#         release/build/macos/client-target/release/benilla.
#
# Needs: Xcode command line tools, Homebrew cmake, mariadb, openssl@3,
# pkg-config, and Rust (rustup).
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
part="${1:-all}"
jobs="$(sysctl -n hw.ncpu)"

build_server() {
    local build="$root/release/build/macos/classic-build"
    local prefix="$root/release/build/macos/server-classic"
    echo "== server: configure"
    cmake -S "$root/server/core" -B "$build" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$prefix" \
        -DBUILD_EXTRACTORS=0 -DUSE_SCRIPTS=1 -DUSE_PCH=1 \
        -DMYSQL_CONFIG="$(brew --prefix)/bin/mysql_config" \
        > "$build.configure.log" 2>&1 || { tail -30 "$build.configure.log"; exit 1; }
    echo "== server: build ($jobs jobs, log: ${build#$root/}.log)"
    cmake --build "$build" -j"$jobs" > "$build.log" 2>&1 || { grep -E "error|Error" "$build.log" | head -30; exit 1; }
    cmake --install "$build" > "$build.install.log" 2>&1
    echo "== server: installed into ${prefix#$root/}"
}

build_client() {
    echo "== client: cargo build --release -p benilla"
    (
        cd "$root/client"
        WOW_DATA="$root/Data" CARGO_TARGET_DIR="$root/release/build/macos/client-target" \
            cargo build --release -p benilla
    )
    echo "== client: release/build/macos/client-target/release/benilla"
}

case "$part" in
    server) build_server ;;
    client) build_client ;;
    all) build_server; build_client ;;
    *) echo "usage: $0 [server|client|all]" >&2; exit 2 ;;
esac
