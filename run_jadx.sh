#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
mkdir -p jadx_out
for f in $(find dex -name '*.dex' | sort); do
  name=$(echo "$f" | sed 's#dex/##; s#/#_#g; s#\.dex$##')
  [ -d "jadx_out/$name" ] && continue
  echo "=== $name start $(date +%H:%M:%S) ==="
  java -Xmx1600m -cp tools/jadx/lib/jadx-1.5.6-all.jar jadx.cli.JadxCLI --no-res -d "jadx_out/$name" "$f" 2>&1 | tail -2
  echo "=== $name end $(date +%H:%M:%S) files=$(find jadx_out/$name -name '*.java' | wc -l) ==="
done
echo "=== ALL DONE $(date +%H:%M:%S) ==="
