#!/usr/bin/env bash
# Baixa as ferramentas usadas na análise. Não são versionadas (ver .gitignore).
set -euo pipefail
cd "$(dirname "$0")"

JADX_VERSION=1.5.6
APKTOOL_VERSION=3.0.3

mkdir -p tools

if [ ! -d tools/jadx ]; then
  echo "baixando jadx ${JADX_VERSION}"
  curl -sL -o tools/jadx.zip \
    "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip"
  7z x -y -otools/jadx tools/jadx.zip > /dev/null
  chmod +x tools/jadx/bin/jadx tools/jadx/bin/jadx-gui
  rm -f tools/jadx.zip
else
  echo "jadx já presente"
fi

if [ ! -f tools/apktool.jar ]; then
  echo "baixando apktool ${APKTOOL_VERSION}"
  curl -sL -o tools/apktool.jar \
    "https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/apktool_${APKTOOL_VERSION}.jar"
else
  echo "apktool já presente"
fi

echo "ok: tools/jadx, tools/apktool.jar"
