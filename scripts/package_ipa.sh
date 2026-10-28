#!/bin/bash
# Turns the app Theos staged during `make package` into an unsigned-style IPA
# (Payload/LiquidGlassLab.app, ldid fake-signed by Theos) and collects the
# .deb next to it in out/.
set -euo pipefail
cd "$(dirname "$0")/.."

version="$(awk '/^Version:/ {print $2}' control)"
app="$(find .theos/_ -type d -name 'LiquidGlassLab.app' -print -quit 2>/dev/null || true)"
if [ -z "$app" ]; then
  echo "LiquidGlassLab.app not found under .theos/_ (run make package first)" >&2
  exit 1
fi
if [ ! -x "$app/LiquidGlassLab" ]; then
  echo "Executable missing: $app/LiquidGlassLab" >&2
  exit 1
fi

rm -rf build/ipa out
mkdir -p build/ipa/Payload out
cp -R "$app" build/ipa/Payload/
( cd build/ipa && zip -qry "../../out/LiquidGlassLab-${version}.ipa" Payload )
find packages -maxdepth 1 -type f -name '*.deb' -exec cp {} out/ \; 2>/dev/null || true
ls -l out
