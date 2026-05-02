#!/usr/bin/env bash
# Generate vim help documentation from LuaCATS annotations using vimcats.
# Requires: vimcats (https://github.com/mrcjkb/vimcats)

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/doc/anki.txt"

vimcats \
  -f -c -a -t \
  "$root/lua/anki/init.lua" \
  "$root/lua/anki/config.lua" \
  > "$out"

echo "Generated $out"