#!/usr/bin/env bash
# VELTEIN one-click provisioner for Sunmi V2 PRO (and similar Android POS).
# Waits for the device, installs the apps, and provisions the live server.
#
#   Usage:  bash scripts/provision.sh
#   APK_DIR defaults to the folder ABOVE this repo (where the .apk files live).
set -u
export MSYS_NO_PATHCONV=1   # keep Git Bash from mangling Android paths

ADB="${ADB:-adb}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"        # repo root
APK_DIR="${APK_DIR:-$(cd "$HERE/.." && pwd)}"   # where the APKs are
KEY="${KEY:-$APK_DIR/sunmi_key}"
[ -f "$KEY" ] || KEY="$APK_DIR/rom_flash/downloads/sunmi_key"
RAW_BOOT='pkg update -y && pkg install -y wget && wget -qO- https://raw.githubusercontent.com/ssassam/sunmi-v2-pro-unlock/main/scripts/termux_bootstrap.sh | bash'

# APK -> package name
TERMUX_APK="$APK_DIR/termux_v0.118.0_armv7.apk"
TBOOT_APK="$APK_DIR/apps_extra/termux-boot-app_v0.8.1+github.debug.apk"
HOME_APK="$APK_DIR/veltein_home/build/veltein-home.apk"
PRINT_APK="$APK_DIR/veltein_print/build/veltein-print.apk"

c() { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }      # color echo
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

# ---------- 1. wait for an authorized device ----------
wait_device() {
  step "STEP 1/5  Connect the POS"
  echo "  1) Plug the POS into this PC with a USB cable."
  echo "  2) On the POS: Settings > About > tap 'Build number' x7 (Developer options)."
  echo "  3) Settings > Developer options > enable 'USB debugging'."
  echo "  4) When 'Allow USB debugging?' pops up: check 'Always allow' and tap ALLOW."
  echo "     (Locked/kiosk unit with no popup? Factory-reset from recovery first —"
  echo "      see docs/unlock-method.md — then re-run this script.)"
  echo
  c '33' "Waiting for device..."
  while :; do
    local line state
    line="$($ADB devices | sed '1d' | grep -v '^[[:space:]]*$' | head -1)"
    state="$(printf '%s' "$line" | awk '{print $2}')"
    case "$state" in
      device)       c '1;32' "  [OK] device authorized."; return 0 ;;
      unauthorized) c '33'   "  Device seen but UNAUTHORIZED — tap ALLOW on the POS screen..." ;;
      offline)      c '33'   "  Device offline — reconnect the cable..." ;;
      "")           : ;;  # nothing yet
    esac
    sleep 2
  done
}

# ---------- 2. install the APKs ----------
install_one() {  # <apk> <label>
  local apk="$1" label="$2"
  if [ ! -f "$apk" ]; then c '33' "  [skip] $label not found: $apk"; return 0; fi
  printf '  installing %-16s ... ' "$label"
  if $ADB install -r -g "$apk" >/tmp/vt_inst 2>&1 || $ADB install -r "$apk" >/tmp/vt_inst 2>&1; then
    c '1;32' "OK"
  else
    c '31' "FAILED"; tail -1 /tmp/vt_inst
  fi
}
install_apks() {
  step "STEP 2/5  Install Termux + VELTEIN apps"
  install_one "$TERMUX_APK" "Termux"
  install_one "$TBOOT_APK"  "Termux:Boot"
  install_one "$HOME_APK"   "VELTEIN home"
  install_one "$PRINT_APK"  "VELTEIN printer"
}

# ---------- 3. set the VELTEIN home launcher ----------
set_launcher() {
  step "STEP 3/5  Set VELTEIN as the home screen"
  $ADB shell "cmd package set-home-activity com.veltein.home/.HomeActivity" >/dev/null 2>&1 \
    && c '1;32' "  [OK] default launcher = VELTEIN" \
    || c '33' "  [warn] could not set launcher (set it by hand: tap HOME > VELTEIN)"
}

# ---------- 4. provision the server inside Termux ----------
type_line() {  # types a command into the focused Termux terminal, then Enter
  local enc; enc="$(printf '%s' "$1" | sed 's/ /%s/g')"
  $ADB shell "input text '$enc'"; sleep 0.4
  $ADB shell "input keyevent 66"
}
provision_server() {
  step "STEP 4/5  Provision the Linux server (inside Termux)"
  echo "  Opening Termux. On FIRST launch it downloads its base system (~1 min)."
  $ADB shell "monkey -p com.termux -c android.intent.category.LAUNCHER 1" >/dev/null 2>&1
  echo
  c '33' "  >> Watch the POS. When Termux shows a '\$' prompt, press ENTER here."
  read -r _
  echo "  Sending the installer command to Termux..."
  type_line "$RAW_BOOT"
  echo "  Installer is running on the device (fetching packages + server files)."
}

# ---------- 5. verify ----------
verify() {
  step "STEP 5/5  Verify the server came up"
  local ip="" tries=0
  echo "  Waiting for SSH (:8022) to answer..."
  while [ $tries -lt 40 ]; do
    if [ -f "$KEY" ]; then
      ip="$($ADB shell "ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print \$2}'" | tr -d '\r')"
      if [ -n "$ip" ] && timeout 8 ssh -i "$KEY" -p 8022 \
           -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           -o ConnectTimeout=5 "$ip" 'echo up' >/dev/null 2>&1; then
        c '1;32' "  [OK] SSH up at $ip:8022"
        ssh -i "$KEY" -p 8022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            "$ip" 'cat $PREFIX/share/nginx/html/stats.json' 2>/dev/null
        break
      fi
    fi
    tries=$((tries+1)); sleep 6
  done
  [ $tries -ge 40 ] && c '33' "  [warn] SSH not confirmed yet — the device may still be installing."
  echo
  $ADB shell "cmd package set-home-activity com.veltein.home/.HomeActivity" >/dev/null 2>&1
  $ADB shell "input keyevent KEYCODE_HOME" >/dev/null 2>&1
  sleep 3
  local shot="$APK_DIR/provision_result.png"
  $ADB exec-out screencap -p > "$shot" 2>/dev/null && c '1;32' "  home screenshot -> $shot"
  hr; c '1;32' "  DONE. The POS now shows the live SERVER MODE dashboard."
  echo "  SSH:  ssh -i \"$KEY\" -p 8022 <device-ip>"
}

main() {
  banner
  command -v "$ADB" >/dev/null 2>&1 || { c '31' "adb not found on PATH. Install Android platform-tools."; exit 1; }
  wait_device
  install_apks
  set_launcher
  provision_server
  verify
}
main "$@"
