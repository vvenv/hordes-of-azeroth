#!/bin/bash
# Installs the 1.12 addon set into the client's addon folder
# (benilla-config/AddOns):
#   - the third-party addons vetted in ../wow-data/addons (pfUI, pfQuest,
#     Atlas, AtlasLoot, AtlasQuest, Bagshui, ShaguKill, ShaguNotify,
#     SuperMacro, CleverMacro); the client's own Blizzard_* folders are skipped;
#   - GMBox and !Solo from this repository (Interface/AddOns): the dungeon
#     and bot panel, and the single-player defaults.
#
# The first run also copies their saved settings (Bagshui's excepted) from the old zhCN client
# (../wow-data/client-zhCN/WTF/Account/ADMIN/SavedVariables) into
# benilla-config/saved, unless a settings file is already there.
#
#   tools/macos/install-addons.sh            (ADDONS_SRC=... to use another folder)
#
# A new addon shows only after a full client restart, not after /reload.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
src="${ADDONS_SRC:-$root/../wow-data/addons}"
old_saved="${OLD_SAVED:-$root/../wow-data/client-zhCN/WTF/Account/ADMIN/SavedVariables}"
home="${BENILLA_HOME:-$root/benilla-config}"
dest="$home/AddOns"
mkdir -p "$dest" "$home/saved"

if [ -d "$src" ]; then
    for dir in "$src"/*/; do
        name="$(basename "$dir")"
        case "$name" in
            Blizzard_*|GMBox|'!Solo') continue ;;
        esac
        rsync -a --delete "$dir" "$dest/$name/"
        echo "addon $name"
    done
else
    echo "no third-party addons at $src, skipped" >&2
fi

# Chinese for the addons that lack it, and two AtlasLoot zhCN fixes, on the
# installed copies (see tools/macos/localize-addons.py).
python3 "$root/tools/macos/localize-addons.py" "$dest"

# This repository's own addons: GMBox, and !Solo (single-player defaults:
# no chat chatter, pfUI and pfQuest set up for travelling alone).
for name in GMBox '!Solo'; do
    rsync -a --delete "$root/Interface/AddOns/$name/" "$dest/$name/"
    echo "addon $name (repo)"
done

if [ -d "$old_saved" ]; then
    for f in "$old_saved"/*.lua; do
        name="$(basename "$f" .lua)"
        [ -d "$dest/$name" ] || continue
        # Bagshui stores its category and group names as text: the old
        # client's are English, so it starts fresh and names them in Chinese.
        [ "$name" = "Bagshui" ] && continue
        if [ ! -f "$home/saved/$name.lua" ]; then
            cp "$f" "$home/saved/$name.lua"
            echo "settings $name"
        fi
    done
fi
