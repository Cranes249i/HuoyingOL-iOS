#!/usr/bin/env bash
# Packages MobileGame.swf into an iOS IPA with the AIR SDK (ADT).
#
#   AIR_SDK=/path/to/airsdk ./build-ipa.sh [target]
#
# target defaults to ipa-test-interpreter: the interpreter targets are the only
# iOS targets that may execute ActionScript from SWFs loaded at runtime, which
# this launcher relies on (it downloads entry.swf from the official CDN).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

AIR_SDK="${AIR_SDK:?set AIR_SDK to the extracted AIR SDK directory}"
TARGET="${1:-ipa-test-interpreter}"
P12_PASSWORD="${P12_PASSWORD:-huoying}"
OUT="${OUT:-build/HuoyingOL.ipa}"

ADT_JAR="$AIR_SDK/lib/adt.jar"
[[ -f "$ADT_JAR" ]] || { echo "adt.jar not found under $AIR_SDK"; exit 1; }

bash ./make-signing.sh cert

if [[ -d src && "${SKIP_COMPILE:-0}" != 1 ]]; then
  echo "== compiling src/MobileGame.as"
  MXMLC="$AIR_SDK/bin/mxmlc"
  [[ -f "$MXMLC.bat" && "${OSTYPE:-}" == msys* ]] && MXMLC="$MXMLC.bat"
  "$MXMLC" +configname=air -swf-version=32 -debug=false -optimize=true \
    -source-path+=src -output MobileGame.swf src/MobileGame.as
  ls -l MobileGame.swf
fi

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"

echo "== ADT version"
java -jar "$ADT_JAR" -version

echo "== packaging ($TARGET)"
java -Xmx2g -jar "$ADT_JAR" -package \
  -target "$TARGET" \
  -storetype pkcs12 -keystore cert/ios-dev.p12 -storepass "$P12_PASSWORD" \
  -provisioning-profile cert/HuoyingOL.mobileprovision \
  "$OUT" HuoyingOL-ios.xml \
  MobileGame.swf qq-return.js icons

ls -l "$OUT"
echo "== IPA contents"
unzip -l "$OUT" 2>/dev/null || python -c "import zipfile,sys; [print(i.file_size, i.filename) for i in zipfile.ZipFile(sys.argv[1]).infolist()]" "$OUT"
