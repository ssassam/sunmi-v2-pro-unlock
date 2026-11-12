# How we installed Termux on the locked Sunmi V2 PRO

The Sunmi ships locked down: **no file manager, no browser, no usable app store**, and
non-store APK taps do nothing. So you cannot sideload Termux from the device UI. The only
working path is **ADB** (after the unlock in [`unlock-method.md`](unlock-method.md)).

## 1. Pick the right ABI
The V2 PRO is **32-bit** (`armeabi-v7a`, Android 7.1.2). Use the **armv7** Termux build —
the universal/arm64 builds will not install/run here.
```bash
adb -s $D shell getprop ro.product.cpu.abi      # -> armeabi-v7a
```

## 2. Verify the APK you downloaded (F-Droid build)
Match the signing key so add-ons (e.g. Termux:Boot) stay compatible later.
```bash
apksigner verify --print-certs termux_v0.118.0_armv7.apk
# Signer #1 certificate SHA-256 digest:
#   b6da01480eefd5fbf2cd3771b8d1021ec791304bdd6c4bf41d3faabad48ee5e1   <- F-Droid Termux key
```
> Keep the whole Termux family (app + Termux:Boot/API) on this **same** F-Droid key.

## 3. Install over ADB and launch
```bash
adb -s $D install -r -g termux_v0.118.0_armv7.apk
adb -s $D shell monkey -p com.termux -c android.intent.category.LAUNCHER 1
# confirm it isn't blocked by the kiosk:
adb -s $D shell dumpsys window | grep mCurrentFocus    # -> com.termux/.app.TermuxActivity
```

## 4. (Reference) the MTP dead-end
Before ADB was authorized we could copy the APK to the device over **MTP**
(`Shell.Application` → `V2_PRO` → Internal storage → Download), but with **no file manager**
there was nothing to tap it with, so MTP alone cannot install here. ADB is required.

## 5. Driving Termux from the PC before SSH exists
Termux runs in its own sandbox; `adb shell` is the `shell` user, not Termux. To run the
first commands (install OpenSSH, set up keys), **type into Termux's foreground terminal**:
```bash
# single-quote the payload so the device shell doesn't eat  >  &  |
adb -s $D shell "input text 'pkg install -y openssh openssl'"
adb -s $D shell input keyevent 66        # 66 = Enter
```
Verify a typed command actually ran by writing a marker to shared storage
(grant it first): `adb shell pm grant com.termux android.permission.WRITE_EXTERNAL_STORAGE`,
then type `id>/sdcard/tok.txt` and read it back with `adb shell cat /sdcard/tok.txt`.

Once OpenSSH + an authorized key are in place and `sshd` is running (port **8022**), drop
the `input` typing and manage everything over real SSH from the PC.
