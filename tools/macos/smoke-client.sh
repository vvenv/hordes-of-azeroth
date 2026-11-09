#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
client="${HOA_CLIENT:-$root/release/build/macos/client-target/release/HordesOfAzeroth}"
if [ ! -x "$client" ]; then
  client="$root/release/build/macos/client/HordesOfAzeroth"
fi
mkdir -p "$root/Interface/GlueXML" "$root/Logs" "$root/benilla-config/AddOns"
printf '%s\n' 'BONK_ACCOUNT = "PLAYER";' 'BONK_PASSWORD = "player";' 'HOA_LANGUAGE = "enUS";' > "$root/Interface/GlueXML/BonkAccount.lua"
printf '%s\n' 'BONK_STATS = nil;' > "$root/Interface/GlueXML/BonkStats.lua"
if [ -d "$root/Interface/AddOns/HordesOfAzeroth" ] && [ ! -e "$root/benilla-config/AddOns/HordesOfAzeroth" ]; then
  cp -a "$root/Interface/AddOns/HordesOfAzeroth" "$root/benilla-config/AddOns/"
fi
export WOW_DATA="${WOW_DATA:-$root/Data}"
export WOW_HOST="${WOW_HOST:-127.0.0.1}"
export WOW_USER="${WOW_USER:-PLAYER}"
export WOW_PASS="${WOW_PASS:-player}"
export WOW_REALM="${WOW_REALM:-Hordes of Azeroth}"
export WGPU_BACKEND="${WGPU_BACKEND:-metal}"
export WOW_UNATTENDED="${WOW_UNATTENDED:-1}"
# WOW_RIG needs a client built WITH default/dev features (not --no-default-features ship).
export WOW_RIG="${WOW_RIG:-human warrior 1}"
cd "$root"
exec "$client" "$@"
