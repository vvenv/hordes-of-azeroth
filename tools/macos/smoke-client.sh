#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
client="${HOA_CLIENT:-$root/release/build/macos/client-target/release/HordesOfAzeroth}"
if [ ! -x "$client" ]; then
  client="$root/release/build/macos/client/HordesOfAzeroth"
fi
mkdir -p "$root/Interface/GlueXML" "$root/Logs" "$root/benilla-config/AddOns" "$root/client"
printf '%s\n' 'BONK_ACCOUNT = "PLAYER";' 'BONK_PASSWORD = "player";' 'HOA_LANGUAGE = "enUS";' > "$root/Interface/GlueXML/BonkAccount.lua"
printf '%s\n' 'BONK_STATS = nil;' > "$root/Interface/GlueXML/BonkStats.lua"
# WOW_RIG character names need a checkout identity word.
if [ ! -f "$root/client/.probe-identity" ]; then
  printf '%s\n' 'WOW_USER=PLAYER' 'WOW_CHAR=Probesmoke' 'WOW_PASS=player' > "$root/client/.probe-identity"
fi
# Unattended runs otherwise use a temp benilla-config, which hides repo AddOns textures.
export BENILLA_HOME="${BENILLA_HOME:-$root/benilla-config}"
if [ -d "$root/Interface/AddOns/HordesOfAzeroth" ]; then
  mkdir -p "$BENILLA_HOME/AddOns"
  rsync -a --delete "$root/Interface/AddOns/HordesOfAzeroth/" "$BENILLA_HOME/AddOns/HordesOfAzeroth/"
fi
export WOW_DATA="${WOW_DATA:-$root/Data}"
export WOW_HOST="${WOW_HOST:-127.0.0.1}"
export WOW_USER="${WOW_USER:-PLAYER}"
export WOW_PASS="${WOW_PASS:-player}"
export WOW_REALM="${WOW_REALM:-Hordes of Azeroth}"
export WGPU_BACKEND="${WGPU_BACKEND:-metal}"
export WOW_UNATTENDED="${WOW_UNATTENDED:-1}"
# Needs a client built WITH default/dev features (cargo build --release -p hoa).
# Skip auto-rig when the caller already named a character, or set WOW_RIG= to clear.
if [ -z "${WOW_RIG+x}" ] && [ -z "${WOW_CHAR:-}" ]; then
  export WOW_RIG="human warrior 1"
fi
# BonkGlue hijacks stock create/select; for first-time WOW_RIG create set HOA_STOCK_GLUE=1.
if [ "${HOA_STOCK_GLUE:-0}" = 1 ]; then
  toc="$root/Interface/GlueXML/GlueXML.toc"
  if [ ! -f "$toc.bonk" ]; then cp "$toc" "$toc.bonk"; fi
  grep -v -E 'BonkGlue|BonkCoop|BonkGluePad|BonkGlueLocale' "$toc.bonk" > "$toc"
  trap 'mv -f "$toc.bonk" "$toc" 2>/dev/null || true' EXIT
fi
cd "$root"
exec "$client" "$@"
