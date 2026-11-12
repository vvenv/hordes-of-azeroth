#!/bin/bash
# Installs the 1.12 addon set into the client's addon folder
# (benilla-config/AddOns):
#   - the third-party addons vetted in ../wow-data/addons (pfUI, pfQuest,
#     Atlas, AtlasLoot, AtlasQuest, Bagshui, ShaguKill, ShaguNotify,
#     SuperMacro, CleverMacro); the client's own Blizzard_* folders are skipped;
#   - GMBox from this repository (Interface/AddOns/GMBox), which has the
#     dungeon and bot panel the classic server needs.
#
# The first run also copies their saved settings from the old zhCN client
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
            Blizzard_*|GMBox) continue ;;
        esac
        rsync -a --delete "$dir" "$dest/$name/"
        echo "addon $name"
    done
else
    echo "no third-party addons at $src, skipped" >&2
fi

# AtlasLoot's zhCN strings give one entry the value `true`, which AceLocale
# allows only in the base (enUS) table: on a Chinese client the whole
# translation file errors out and every loot table after it fails to load.
cn="$dest/AtlasLoot/Locale/locale.cn.lua"
if [ -f "$cn" ]; then
    python3 - "$cn" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8-sig").read()
old = '["Left-click to open AtlasLoot.\\nMiddle-click for AtlasLoot options.\\nRight-click and drag to move this button."] = true,'
new = '["Left-click to open AtlasLoot.\\nMiddle-click for AtlasLoot options.\\nRight-click and drag to move this button."] = "左键打开 AtlasLoot。\\n中键打开 AtlasLoot 设置。\\n右键拖动可移动此按钮。",'
if old in s:
    open(p, "w", encoding="utf-8").write("﻿" + s.replace(old, new))
    print("patched AtlasLoot zhCN strings")
PY
fi

# Its zhCN loot table titles come from the TBC release and name tables this
# 1.12 build lacks (BCKeys, Auchindoun...); the first missing one stops the
# file, so no title gets its Chinese name. Only set the ones that exist.
titles="$dest/AtlasLoot/TableRegister/loottables.cn.lua"
if [ -f "$titles" ]; then
    python3 - "$titles" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8-sig").read()
pat = re.compile(r'^(\s*)AtlasLoot_TableNames\["([^"]+)"\]\[1\] = *(".*?");?\s*$', re.M)
t = pat.sub(r'\1if AtlasLoot_TableNames["\2"] then AtlasLoot_TableNames["\2"][1] = \3 end', s)
if t != s:
    open(p, "w", encoding="utf-8").write("﻿" + t)
    print("patched AtlasLoot zhCN loot table titles")
PY
fi

rsync -a --delete "$root/Interface/AddOns/GMBox/" "$dest/GMBox/"
echo "addon GMBox (repo)"

if [ -d "$old_saved" ]; then
    for f in "$old_saved"/*.lua; do
        name="$(basename "$f" .lua)"
        [ -d "$dest/$name" ] || continue
        if [ ! -f "$home/saved/$name.lua" ]; then
            cp "$f" "$home/saved/$name.lua"
            echo "settings $name"
        fi
    done
fi
