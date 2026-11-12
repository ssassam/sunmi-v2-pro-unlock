#!/usr/bin/env bash
# VELTEIN one-click provisioner for Sunmi V2 PRO (and similar Android POS).
# Self-contained: auto-downloads every app it needs (with progress), waits for
# the device, installs them, and provisions the live server.
#
#   Usage:  double-click provision.bat   (or)   bash scripts/provision.sh
set -u
export MSYS_NO_PATHCONV=1   # keep Git Bash from mangling Android paths

ADB="${ADB:-adb}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"          # repo root
CACHE="${CACHE:-$HERE/.payload}"; mkdir -p "$CACHE"
RAW='https://raw.githubusercontent.com/ssassam/sunmi-v2-pro-unlock/master'
RAW_BOOT="pkg update -y && pkg install -y wget && wget -qO- $RAW/scripts/termux_bootstrap.sh | bash"

# private SSH key used to verify the server (optional; search common spots)
KEY="${KEY:-}"
for k in "$KEY" "$HERE/../sunmi_key" "$HERE/../rom_flash/downloads/sunmi_key" "$HERE/sunmi_key"; do
  [ -n "$k" ] && [ -f "$k" ] && { KEY="$k"; break; }
done

# download sources: Termux from its official releases, VELTEIN apps from this repo
U_TERMUX="https://github.com/termux/termux-app/releases/download/v0.118.0/termux-app_v0.118.0+github-debug_armeabi-v7a.apk"
U_TBOOT="https://github.com/termux/termux-boot/releases/download/v0.8.1/termux-boot-app_v0.8.1+github.debug.apk"
U_HOME="$RAW/prebuilt/veltein-home.apk"
U_PRINT="$RAW/prebuilt/veltein-print.apk"
TERMUX_APK="$CACHE/termux.apk"; TBOOT_APK="$CACHE/termux-boot.apk"
HOME_APK="$CACHE/veltein-home.apk"; PRINT_APK="$CACHE/veltein-print.apk"

c() { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
hr(){ printf '%s\n' "------------------------------------------------------------"; }
step(){ hr; c '1;36' ">> $*"; }

banner() {
  c '1;32' '
   __     _______ _   _____ _____ ___ _   _
   \ \   / / ____| | |_   _| ____|_ _| \ | |
    \ \ / /|  _| | |   | | |  _|  | ||  \| |
     \ V / | |___| |___| | | |___ | || |\  |
      \_/  |_____|_____|_| |_____|___|_| \_|   under FAFOFI CORP'
  echo "        Sunmi V2 PRO  ->  unlocked Linux server + live dashboard"
  echo
}

# ---------- download helper (with progress bar) ----------
fetch() {  # <url> <dest> <label>
  local url="$1" dst="$2" label="$3"
  if [ -f "$dst" ] && [ -s "$dst" ]; then c '0;32' "  [cached]  $label"; return 0; fi
  c '36' "  downloading $label ..."
  if curl -L --fail --progress-bar -o "$dst.part" "$url" && mv -f "$dst.part" "$dst"; then
    c '1;32' "  [OK] $label  ($(du -h "$dst" 2>/dev/null | cut -f1))"
  else
    rm -f "$dst.part"; c '31' "  [FAIL] $label  <- $url"; return 1
  fi
}

# ---------- 1. wait for an authorized device ----------
wait_device() {
  step "STEP 1/6  Connect the POS"
  echo "  1) Plug the POS into this PC with a USB cable (use a DATA cable + rear port)."
  echo "  2) On the POS: Settings > About > tap 'Build number' x7 (Developer options)."
  echo "  3) Settings > Developer options > enable 'USB debugging'."
  echo "  4) When 'Allow USB debugging?' pops up: check 'Always allow' and tap ALLOW."
  echo "     (Locked/kiosk unit with no popup? Factory-reset from recovery first —"
  echo "      see docs/unlock-method.md — then re-run.)"
  echo
  c '33' "Waiting for device..."
  while :; do
    local line state
    line="$($ADB devices | sed '1d' | grep -v '^[[:space:]]*$' | head -1)"
    state="$(printf '%s' "$line" | awk '{print $2}')"
    case "$state" in
      device)       c '1;32' "  [OK] device authorized."; return 0 ;;
      unauthorized) c '33'   "  Device seen but UNAUTHORIZED — tap ALLOW on the POS screen..." ;;
      offline)      c '33'   "  Device offline — reseat the cable..." ;;
    esac
    sleep 2
  done
}

# ---------- 2. download everything ----------
download_payload() {
  step "STEP 2/6  Download the app payload"
  echo "  (cached in $CACHE — only downloads what's missing)"
  fetch "$U_TERMUX" "$TERMUX_APK" "Termux (~29 MB)"       || true
  fetch "$U_TBOOT"  "$TBOOT_APK"  "Termux:Boot"           || true
  fetch "$U_HOME"   "$HOME_APK"   "VELTEIN home"          || true
  fetch "$U_PRINT"  "$PRINT_APK"  "VELTEIN printer"       || true
}

# ---------- 3. install the APKs ----------
install_one() {  # <apk> <label>
  local apk="$1" label="$2"
  if [ ! -f "$apk" ]; then c '33' "  [skip] $label not downloaded"; return 0; fi
  printf '  installing %-16s ... ' "$label"
  local wapk; wapk="$(cygpath -w "$apk" 2>/dev/null || echo "$apk")"  # adb.exe needs a Windows path
  if $ADB install -r -g "$wapk" >/tmp/vt_inst 2>&1 || $ADB install -r "$wapk" >/tmp/vt_inst 2>&1; then
    c '1;32' "OK"
  else
    c '31' "FAILED"; tail -1 /tmp/vt_inst
  fi
}
install_apks() {
  step "STEP 3/6  Install Termux + VELTEIN apps"
  install_one "$TERMUX_APK" "Termux"
  install_one "$TBOOT_APK"  "Termux:Boot"
  install_one "$HOME_APK"   "VELTEIN home"
  install_one "$PRINT_APK"  "VELTEIN printer"
}

# ---------- 4. set the VELTEIN home launcher ----------
set_launcher() {
  step "STEP 4/6  Set VELTEIN as the home screen"
  $ADB shell "cmd package set-home-activity com.veltein.home/.HomeActivity" >/dev/null 2>&1 \
    && c '1;32' "  [OK] default launcher = VELTEIN" \
    || c '33' "  [warn] could not set launcher (set it by hand: tap HOME > VELTEIN)"
}

# ---------- 5. provision the server inside Termux ----------
type_line() {  # types a command into the focused Termux terminal, then Enter
  local enc; enc="$(printf '%s' "$1" | sed 's/ /%s/g')"
  $ADB shell "input text '$enc'"; sleep 0.4
  $ADB shell "input keyevent 66"
}
provision_server() {
  step "STEP 5/6  Provision the Linux server (inside Termux)"
  echo "  Opening Termux. On FIRST launch it downloads its base system (~1 min)."
  $ADB shell "monkey -p com.termux -c android.intent.category.LAUNCHER 1" >/dev/null 2>&1
  echo
  c '33' "  >> Watch the POS. When Termux shows a '\$' prompt, press ENTER here."
  read -r _
  echo "  Sending the installer command to Termux..."
  type_line "$RAW_BOOT"
  echo "  Installer is running on the device (fetching packages + server files)."
}

# ---------- 6. verify ----------
verify() {
  step "STEP 6/6  Verify the server came up"
  local ip="" tries=0
  if [ -z "$KEY" ]; then c '33' "  [note] no SSH key found locally — skipping SSH check."; fi
  echo "  Waiting for SSH (:8022) to answer..."
  while [ -n "$KEY" ] && [ $tries -lt 40 ]; do
    ip="$($ADB shell "ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print \$2}'" | tr -d '\r')"
    if [ -n "$ip" ] && timeout 8 ssh -i "$KEY" -p 8022 \
         -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
         -o ConnectTimeout=5 "$ip" 'echo up' >/dev/null 2>&1; then
      c '1;32' "  [OK] SSH up at $ip:8022"
      ssh -i "$KEY" -p 8022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          "$ip" 'cat $PREFIX/share/nginx/html/stats.json' 2>/dev/null
      break
    fi
    tries=$((tries+1)); sleep 6
  done
  [ -n "$KEY" ] && [ $tries -ge 40 ] && c '33' "  [warn] SSH not confirmed — device may still be installing."
  echo
  $ADB shell "cmd package set-home-activity com.veltein.home/.HomeActivity" >/dev/null 2>&1
  $ADB shell "input keyevent KEYCODE_HOME" >/dev/null 2>&1
  sleep 3
  local shot="$HERE/provision_result.png"
  $ADB exec-out screencap -p > "$shot" 2>/dev/null && c '1;32' "  home screenshot -> $shot"
  hr; c '1;32' "  DONE. The POS now shows the live SERVER MODE dashboard."
  [ -n "$KEY" ] && echo "  SSH:  ssh -i \"$KEY\" -p 8022 <device-ip>"
}

main() {
  banner
  command -v "$ADB"  >/dev/null 2>&1 || { c '31' "adb not found on PATH. Install Android platform-tools."; exit 1; }
  command -v curl    >/dev/null 2>&1 || { c '31' "curl not found. Install curl (ships with Git for Windows)."; exit 1; }
  wait_device
  download_payload
  install_apks
  set_launcher
  provision_server
  verify
}
main "$@"
