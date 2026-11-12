# VELTEIN — Sunmi V2 PRO Liberation

Turn a **locked Sunmi V2 PRO** payment terminal into a **general-purpose Android device
+ a small Linux server**, with a custom Matrix-style home screen and a POS printer app —
**without rooting, flashing, or opening the case.**

> Hardware: Sunmi V2 PRO (Qualcomm MSM8917 / Snapdragon 425, Android 7.1.2, armv7l).
> Branding in this build: **VELTEIN — under FAFOFI CORP**.

---

## What you get

| Feature | How |
|---|---|
| Install any APK, use Play Store / YouTube | ADB + the device already ships with Google Play Services |
| Kiosk launcher removed | `pm disable-user` the Sunmi/POS launchers, set **KISS** as home |
| Matrix "VELTEIN" home screen | custom WebView launcher app (`apps/veltein_home`) |
| POS printer **form** app | binds Sunmi's printer AIDL (`apps/veltein_print`) |
| Linux server (web + SSH + dashboard) | **Termux** running nginx, OpenSSH, Python (`server/`) |

## The key insight (how the lock is beaten)

The Sunmi kiosk **suppresses the ADB "Allow USB debugging" popup**, so a fresh PC can
never authorize — `adb devices` is stuck on `unauthorized`. Nothing (revoke/re-toggle,
reboot, safe mode, USB mode) brings the popup back.

**A factory reset from stock recovery clears that state**: on the next boot the popup
finally appears, you tap **Allow**, and the PC gets full ADB control. From there everything
else is just ADB + Termux. See [`docs/unlock-method.md`](docs/unlock-method.md).

> No root. No QFIL/EDL. No opening the device. (An EDL/Magisk root route exists but was
> **not** needed — see the notes in the unlock doc.)

---

## Repo layout

```
apps/
  veltein_print/   POS printer form app (Sunmi IWoyouService AIDL)
  veltein_home/    Matrix WebView home-screen launcher (+ bundled page)
server/
  index.html       hacker/Matrix VELTEIN web page (served by nginx)
  dashboard.py     live CPU/RAM/battery dashboard (shown on SSH login)
  default_nginx.conf
  start-server.sh  start nginx + sshd inside Termux
scripts/
  build_apk.sh     manual APK build (no gradle): aidl->javac->d8->aapt2->sign
docs/
  unlock-method.md server-setup.md build-apps.md
```

## Quick start

1. **Unlock & authorize ADB** — [`docs/unlock-method.md`](docs/unlock-method.md)
2. **Install apps & set launcher** — same doc (ADB one-liners)
2b. **Install Termux** — [`docs/termux-install.md`](docs/termux-install.md)
3. **Build the two apps** — [`docs/build-apps.md`](docs/build-apps.md) / `scripts/build_apk.sh`
4. **Set up the server** — [`docs/server-setup.md`](docs/server-setup.md)
5. **Live dashboard + boot autostart** — [`docs/live-dashboard-autostart.md`](docs/live-dashboard-autostart.md)

## Requirements (PC)

- `adb` (Android platform-tools)
- Android SDK **build-tools** (provides `aidl`, `aapt2`, `d8`, `apksigner`, `zipalign`) + a platform `android.jar`
- **JDK 17** (for `javac`, `jar`, `keytool`)

## Legal / safety

Only do this to a device **you own**. A factory reset **erases all data**. Disabling POS
apps is reversible (`pm enable <pkg>`). This repo documents making your own hardware
general-purpose; it is not for bypassing someone else's device management.
