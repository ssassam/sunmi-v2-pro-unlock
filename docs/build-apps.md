# Building the two apps (manual, no Gradle)

Pipeline: `aidl → javac → d8 → aapt2 link (+ assets) → add classes.dex → zipalign → apksigner`.
See `scripts/build_apk.sh`.

## Prereqs (set these env vars)
```bash
export JAVA_HOME="/c/Program Files/Microsoft/jdk-17.0.21.21-hotspot"
export ANDROID_SDK="$LOCALAPPDATA/Android/Sdk"
export BT="$ANDROID_SDK/build-tools/36.1.0"        # has aidl, aapt2, d8, apksigner, zipalign
export PLAT="$ANDROID_SDK/platforms/android-36/android.jar"
```

## veltein_print (POS printer form)
Binds `woyou.aidlservice.jiuiv5.IWoyouService` (the exact AIDL is in `apps/veltein_print/aidl`,
method order must match the live service). The UI is built in code (no XML res).
```bash
scripts/build_apk.sh apps/veltein_print com.veltein.print
adb install -r -g apps/veltein_print/build/veltein-print.apk
```

## veltein_home (Matrix home launcher)
Fullscreen WebView launcher; the page is bundled as an **asset**
(`assets/veltein_home.html`) so it renders offline (a WebView can't read /sdcard without
storage permission). Double-tap opens the KISS app drawer so you're never locked out.
```bash
scripts/build_apk.sh apps/veltein_home com.veltein.home
adb install -r -g apps/veltein_home/build/veltein-home.apk
adb shell cmd package set-home-activity com.veltein.home/.HomeActivity
```

## Gotchas learned
- `javac` needs `-encoding UTF-8` (the AIDL has CJK comments).
- `d8` needs `JAVA_HOME` set.
- `aapt2 link` bundles assets with `-A <dir>`; add `classes.dex` to the APK after linking.
- Compile with `--release 8` for dex compatibility.
