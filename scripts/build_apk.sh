#!/usr/bin/env bash
# Manual Android APK build (no Gradle).
# Usage: scripts/build_apk.sh <app_dir> <package_name>
#   requires env: JAVA_HOME, BT, PLAT   (see docs/build-apps.md)
set -euo pipefail

APP="${1:?app dir, e.g. apps/veltein_print}"
PKG="${2:?package, e.g. com.veltein.print}"
NAME="$(basename "$APP")"
: "${JAVA_HOME:?set JAVA_HOME}"; : "${BT:?set BT}"; : "${PLAT:?set PLAT}"
JDK="$JAVA_HOME"; PLATW="$(cygpath -w "$PLAT" 2>/dev/null || echo "$PLAT")"

cd "$APP"
mkdir -p build classes gen        # clean build dirs first if you want a fresh build

# 1. AIDL (if present)
if [ -d aidl ]; then
  for f in $(find aidl -name '*.aidl'); do
    "$BT/aidl.exe" --lang=java -I "$(cygpath -w aidl)" -o "$(cygpath -w gen)" "$(cygpath -w "$f")" || true
  done
fi

# 2. javac (CJK-safe, dex-compatible)
SRCS="$(find src gen -name '*.java' 2>/dev/null)"
"$JDK/bin/javac.exe" -encoding UTF-8 --release 8 -cp "$PLATW" -d classes $SRCS

# 3. dex
"$BT/d8.bat" --min-api 22 --lib "$PLATW" --output build $(find classes -name '*.class')

# 4. link (bundle assets/ if present)
AOPT=""; [ -d assets ] && AOPT="-A $(cygpath -w assets)"
"$BT/aapt2.exe" link -o build/app.apk -I "$PLATW" \
  --manifest "$(cygpath -w AndroidManifest.xml)" $AOPT \
  --min-sdk-version 22 --target-sdk-version 25

# 5. add classes.dex, align, sign (self-signed debug key)
( cd build && "$JAVA_HOME/bin/jar.exe" uf app.apk classes.dex )
"$BT/zipalign.exe" -f 4 build/app.apk build/app-aligned.apk
[ -f build/debug.ks ] || "$JAVA_HOME/bin/keytool.exe" -genkeypair -v -keystore build/debug.ks \
  -storepass android -keypass android -alias a -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=$PKG" >/dev/null 2>&1
OUT="build/${NAME//_/-}.apk"
"$BT/apksigner.bat" sign --ks build/debug.ks --ks-pass pass:android --key-pass pass:android \
  --out "$OUT" build/app-aligned.apk
echo "built: $APP/$OUT"
