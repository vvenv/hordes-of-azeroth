#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
client="${HOA_CLIENT:-$root/release/build/macos/client-target/release/HordesOfAzeroth}"
if [ ! -x "$client" ]; then
  client="$root/release/build/macos/client/HordesOfAzeroth"
fi
if [ ! -x "$client" ]; then
  client="$root/release/build/macos/dev-install/HordesOfAzeroth.arm64"
fi
mkdir -p "$root/Logs" "$root/benilla-config/AddOns" "$root/client"
# WOW_RIG character names need a checkout identity word.
if [ ! -f "$root/client/.probe-identity" ]; then
  printf '%s\n' 'WOW_USER=PLAYER' 'WOW_CHAR=Probesmoke' 'WOW_PASS=player' > "$root/client/.probe-identity"
fi
# Unattended runs otherwise use a temp benilla-config, which hides repo AddOns textures.
export BENILLA_HOME="${BENILLA_HOME:-$root/benilla-config}"
for name in GMBox '!Solo'; do
  [ -d "$root/Interface/AddOns/$name" ] && rsync -a --delete "$root/Interface/AddOns/$name/" "$BENILLA_HOME/AddOns/$name/"
done
export WOW_DATA="${WOW_DATA:-$root/Data}"
export WOW_HOST="${WOW_HOST:-127.0.0.1}"
export WOW_USER="${WOW_USER:-PLAYER}"
export WOW_PASS="${WOW_PASS:-player}"
export WOW_REALM="${WOW_REALM:-Azeroth}"
export WGPU_BACKEND="${WGPU_BACKEND:-metal}"
export WOW_UNATTENDED="${WOW_UNATTENDED:-1}"
# Needs a client built WITH default/dev features (cargo build --release -p hoa).
# Skip auto-rig when the caller already named a character, or set WOW_RIG= to clear.
if [ -z "${WOW_RIG+x}" ] && [ -z "${WOW_CHAR:-}" ]; then
  export WOW_RIG="human warrior 1"
fi
cd "$root"
exec "$client" "$@"
