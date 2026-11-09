#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
run="$root/server/run"
cfg="$root/config"
logs="$root/server/logs"
mkdir -p "$logs"

merge() {
    local name="$1"
    local dist="$run/$name.conf.dist"
    local overrides="$cfg/$name.overrides.conf"
    local target="$run/$name.conf"
    python3 - "$dist" "$overrides" "$target" <<'PY'
import re, sys
dist, overrides, target = sys.argv[1:4]
lines = open(dist, encoding='utf-8', errors='replace').read().splitlines()
applied = 0
for raw in open(overrides, encoding='utf-8', errors='replace'):
    line = raw.rstrip('\n')
    m = re.match(r'\s*([\w.]+)\s*=', line)
    if not m:
        continue
    key = m.group(1)
    pat = re.compile(r'^\s*' + re.escape(key) + r'\s*=')
    for i, existing in enumerate(lines):
        if pat.match(existing):
            lines[i] = line.strip()
            applied += 1
            break
    else:
        raise SystemExit(f"{overrides} sets '{key}', which {dist} does not define.")
open(target, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
print(f'{target}: {applied} override(s)')
PY
}

merge mangosd
merge realmd
