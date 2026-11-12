# Server setup — Termux on the Sunmi (web + SSH + dashboard)

No root. Everything runs inside **Termux**.

## 1. Install Termux (it is blocked in-UI, so push + install via ADB)
```bash
adb -s $D install -r -g termux_v0.118.0_armv7.apk   # armv7 build for this device
adb -s $D shell monkey -p com.termux -c android.intent.category.LAUNCHER 1
```
Connect the device to Wi-Fi (needed for package installs).

## 2. Driving Termux from the PC (before SSH exists)
Termux is an app sandbox; type commands into its foreground terminal with `input`:
```bash
adb -s $D shell "input text 'pkg install -y openssh openssl'"   # single-quote so &,>,| are literal
adb -s $D shell input keyevent 66                               # Enter
```
(Grant storage first so you can read results: `pm grant com.termux android.permission.READ_EXTERNAL_STORAGE`.)

## 3. SSH in (key-based)
```bash
# on PC
ssh-keygen -t ed25519 -f sunmi_key -N "" -C localy
# type into Termux (one line): install key + start sshd
#   mkdir -p ~/.ssh; echo "<sunmi_key.pub contents>" > ~/.ssh/authorized_keys
#   chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys; sshd
# then from PC (Termux ssh listens on 8022):
ssh -p 8022 -i sunmi_key <termux_user>@<device_ip>
```
> Known gotcha on old Termux: `ssh-keygen: libcrypto.so.3 not found` → `pkg install -y openssl`.

## 4. Web server + dashboard
```bash
pkg install -y nginx python
cp index.html $PREFIX/share/nginx/html/index.html
nginx                                  # serves on :8080
# live dashboard on every interactive SSH login:
printf 'case $- in *i*) [ -f ~/dashboard.py ] && python ~/dashboard.py ;; esac\n' > ~/.bash_profile
```
`start-server.sh` restarts both services after a reboot. For true auto-start on boot,
install the **Termux:Boot** addon and drop a script in `~/.termux/boot/`.
