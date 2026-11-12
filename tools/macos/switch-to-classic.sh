#!/bin/bash
# Moves the survivors-mode client files out of the game's way, so the client
# runs the stock 1.12 interface against the classic server:
#   Data/patch-z.MPQ                      (survivors spell visuals)
#   Interface/GlueXML/                    (survivors login and hero screens)
#   benilla-config/AddOns/HordesOfAzeroth (survivors addon, as the client loads it)
# They go to release/survivors-backup/, nothing is deleted. Run with the
# client closed.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
backup="$root/release/survivors-backup"
mkdir -p "$backup/Data" "$backup/Interface" "$backup/benilla-config/AddOns"

move() {
    local from="$1" to="$2"
    if [ -e "$from" ]; then
        rm -rf "$to"
        mv "$from" "$to"
        echo "moved $(basename "$from") -> ${to#$root/}"
    fi
}

move "$root/Data/patch-z.MPQ" "$backup/Data/patch-z.MPQ"
move "$root/Interface/GlueXML" "$backup/Interface/GlueXML"
move "$root/benilla-config/AddOns/HordesOfAzeroth" "$backup/benilla-config/AddOns/HordesOfAzeroth"

