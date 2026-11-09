#!/bin/bash
# Point this checkout at local 1.12.1 data under ../wow-data.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
wow_data="${HOA_WOW_DATA:-$root/../wow-data/client}"

if [ ! -d "$wow_data/Data" ]; then
    echo "missing Data at $wow_data/Data" >&2
    exit 1
fi

link() {
    local name="$1" src="$2"
    local dest="$root/$name"
    if [ -L "$dest" ] || [ -e "$dest" ]; then
        echo "keep $dest"
        return
    fi
    ln -s "$src" "$dest"
    echo "link $dest -> $src"
}

link Data "$wow_data/Data"
link WoW.exe "$wow_data/WoW.exe"

if [ -d "$root/client" ] && [ ! -e "$root/client/WoW" ]; then
    ln -s "$root" "$root/client/WoW"
    echo "link $root/client/WoW -> $root"
fi

echo "WOW_DATA=$wow_data/Data"
