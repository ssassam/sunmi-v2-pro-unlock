# Unlock method — Sunmi V2 PRO (no root, no flashing)

## 0. Symptom
`adb devices` shows the Sunmi as `unauthorized` and the **"Allow USB debugging?"**
popup never appears, because the Sunmi kiosk launcher suppresses system dialogs.
Tried and failed: revoke + re-toggle USB debugging, full reboot, Safe Mode, changing
USB mode. The popup stays hidden.

## 1. The fix: factory reset from recovery
1. Power off. Boot into **stock recovery** (power + volume, or `adb reboot recovery`
   if you briefly have adb).
2. **Wipe data / factory reset.**
3. Reboot. During first-boot setup **skip Wi-Fi** (stops the kiosk re-provisioning).
4. Enable developer mode: **Settings → About → tap Build number 7x**, then
   **Settings → Developer options → USB debugging = ON**.
5. Plug USB — the **"Allow USB debugging?"** popup now appears. Tick *Always allow* → **Allow**.
6. `adb devices` now shows `device`. You have full control.

> Note: a reset may boot into Sunmi "Experience Mode" first; reach Settings from there
> and enable USB debugging — the popup still appears.

## 2. Install the general-use apps
```bash
D=<serial>                      # from: adb devices
adb -s $D install -r -g NewPipe.apk        # YouTube without Google
adb -s $D install -r -g FossBrowser.apk    # browser
adb -s $D install -r -g F-Droid.apk        # FOSS store
adb -s $D install -r -g AuroraStore.apk    # Play apps without GMS login
adb -s $D install -r -g KISSLauncher.apk   # a real launcher
```
The V2 PRO already has Google Play (`com.android.vending`) + Play Services, so you can
also sign in and use the Play Store / YouTube directly (Play Services is old — it may
self-update after sign-in).

## 3. Remove the kiosk, set your launcher (all reversible)
```bash
# disable POS/kiosk launchers + the experience-mode app
adb -s $D shell pm disable-user --user 0 com.ezpaypin.launcher
adb -s $D shell pm disable-user --user 0 com.sunmi.welcome
adb -s $D shell pm disable-user --user 0 com.woyou.launcher
# set KISS (or the VELTEIN home app) as default home
adb -s $D shell cmd package set-home-activity fr.neamar.kiss/.MainActivity
# revert anytime:  adb -s $D shell pm enable <package>
```

## Appendix: the root route we did NOT need
Before the reset worked we prepared a QFIL/EDL + Magisk root (gzalo's guide,
Snapdragon 425 firehose `MSM8917.mbn`). It requires opening the case and shorting
test points. The factory-reset method above made it unnecessary.
